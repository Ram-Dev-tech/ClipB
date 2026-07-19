import SwiftUI
import Combine
import AppKit

enum QuickAccessCategory: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case favorites = "Favorites"
    case pinned = "Pinned"
    case code = "Code"
    case links = "Links"
    case emails = "Emails"
    case images = "Images"
    case files = "Files"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .recent: return "clock"
        case .favorites: return "star.fill"
        case .pinned: return "pin.fill"
        case .code: return "curlybraces"
        case .links: return "link"
        case .emails: return "envelope"
        case .images: return "photo"
        case .files: return "doc"
        }
    }
}

@MainActor
final class QuickAccessViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var selectedCategory: QuickAccessCategory = .recent
    @Published var entries: [ClipboardEntry] = []
    @Published var selectedIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        fetchEntries()
    }
    
    private func setupBindings() {
        Publishers.CombineLatest(
            $searchQuery.debounce(for: .milliseconds(150), scheduler: DispatchQueue.main).removeDuplicates(),
            $selectedCategory
        )
        .sink { [weak self] newQuery, newCategory in
            guard let self = self else { return }
            self.selectedIndex = 0
            self.fetchEntries(query: newQuery, category: newCategory)
        }
        .store(in: &cancellables)
    }
    
    func fetchEntries() {
        fetchEntries(query: searchQuery, category: selectedCategory)
    }
    
    private func fetchEntries(query: String, category: QuickAccessCategory) {
        // Map category to database filters
        var contentType: ContentType? = nil
        var onlyFavorites = false
        var onlyPinned = false
        var startDate: Date? = nil
        
        switch category {
        case .recent: 
            let period = UserDefaults.standard.string(forKey: "quickAccessRecentPeriod") ?? "week"
            if period == "today" {
                startDate = Calendar.current.startOfDay(for: Date())
            } else if period == "week" {
                startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
            }
        case .favorites: onlyFavorites = true
        case .pinned: onlyPinned = true
        case .code: contentType = .code 
        case .links: contentType = .url
        case .emails: contentType = .email 
        case .images: contentType = .image
        case .files: contentType = .file
        }
        
        do {
            var fetched = try DatabaseManager.shared.fetchEntries(
                limit: 100, // Keep it fast for the overlay
                offset: 0,
                contentType: contentType,
                searchQuery: query.isEmpty ? nil : query,
                startDate: startDate
            )
            
            // If AI is enabled and there is a search query, append semantic results
            if !query.isEmpty, UserDefaults.standard.bool(forKey: "aiEnabled") {
                let semanticResults = try DatabaseManager.shared.semanticSearch(query: query, limit: 15)
                var existingIds = Set(fetched.map { $0.id })
                
                // Keep the top 50 exact matches, then append semantic matches, up to 100 total
                for entry in semanticResults {
                    if !existingIds.contains(entry.id) {
                        // Apply the category filters to semantic results too
                        var matchesCategory = true
                        if onlyFavorites && !entry.isFavorite { matchesCategory = false }
                        if onlyPinned && !entry.isPinned { matchesCategory = false }
                        if let ct = contentType, entry.contentType != ct { matchesCategory = false }
                        if let start = startDate, entry.timestamp < start { matchesCategory = false }
                        
                        if matchesCategory {
                            fetched.append(entry)
                            existingIds.insert(entry.id)
                        }
                    }
                }
            }
            
            // Apply client-side filters for things that don't have native DB columns yet if needed
            self.entries = fetched.filter { entry in
                if onlyFavorites && !entry.isFavorite { return false }
                if onlyPinned && !entry.isPinned { return false }
                return true
            }
            
            if selectedIndex >= self.entries.count {
                selectedIndex = max(0, self.entries.count - 1)
            }
            
        } catch {
            print("[QuickAccess] Error fetching entries: \(error)")
        }
    }
    
    func moveSelectionDown() {
        if selectedIndex < entries.count - 1 {
            selectedIndex += 1
        }
    }
    
    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func nextCategory() {
        let allCategories = QuickAccessCategory.allCases
        guard let currentIndex = allCategories.firstIndex(of: selectedCategory) else { return }
        let nextIndex = (currentIndex + 1) % allCategories.count
        selectedCategory = allCategories[nextIndex]
    }
    
    func previousCategory() {
        let allCategories = QuickAccessCategory.allCases
        guard let currentIndex = allCategories.firstIndex(of: selectedCategory) else { return }
        let nextIndex = (currentIndex - 1 + allCategories.count) % allCategories.count
        selectedCategory = allCategories[nextIndex]
    }
    
    func pasteSelected(autoPaste: Bool = false) {
        guard entries.indices.contains(selectedIndex) else { return }
        let entry = entries[selectedIndex]
        
        // 1. Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let data = entry.imageData, let img = NSImage(data: data) {
            pasteboard.writeObjects([img])
        } else if let text = entry.textContent {
            pasteboard.setString(text, forType: .string)
        }
        
        // 2. Hide window to give focus back to previous app
        QuickAccessWindowController.shared.hide()
        
        // 3. Auto paste via Accessibility API if requested
        if autoPaste {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.simulatePasteCommand()
            }
        }
    }
    
    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 0x09 // 'v' key
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    func copyEntry(at index: Int) {
        copyEntryWithoutHiding(at: index)
        QuickAccessWindowController.shared.hide()
    }
    
    func copyEntryWithoutHiding(at index: Int) {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let data = entry.imageData, let img = NSImage(data: data) {
            pasteboard.writeObjects([img])
        } else if let text = entry.textContent {
            pasteboard.setString(text, forType: .string)
        }
    }
    
    func deleteEntry(at index: Int) {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        do {
            try DatabaseManager.shared.deleteEntry(id: entry.id)
            entries.remove(at: index)
            if selectedIndex >= entries.count {
                selectedIndex = max(0, entries.count - 1)
            }
        } catch {
            print("[QuickAccess] Failed to delete entry: \(error)")
        }
    }
    
    func toggleFavorite(at index: Int) {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        do {
            try DatabaseManager.shared.toggleFavorite(id: entry.id)
            entries[index].isFavorite.toggle()
            
            // If filtering by favorites, remove from view immediately
            if selectedCategory == .favorites && !entries[index].isFavorite {
                entries.remove(at: index)
                if selectedIndex >= entries.count {
                    selectedIndex = max(0, entries.count - 1)
                }
            }
        } catch {
            print("[QuickAccess] Failed to toggle favorite: \(error)")
        }
    }
    
    func togglePin(at index: Int) {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        do {
            try DatabaseManager.shared.togglePin(id: entry.id)
            entries[index].isPinned.toggle()
            
            if selectedCategory == .pinned && !entries[index].isPinned {
                entries.remove(at: index)
                if selectedIndex >= entries.count {
                    selectedIndex = max(0, entries.count - 1)
                }
            }
        } catch {
            print("[QuickAccess] Failed to toggle pin: \(error)")
        }
    }
}
