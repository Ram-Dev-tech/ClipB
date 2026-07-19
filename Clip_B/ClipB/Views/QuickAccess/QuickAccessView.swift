import SwiftUI
import UniformTypeIdentifiers

struct QuickAccessView: View {
    @StateObject private var viewModel = QuickAccessViewModel()
    
    // Focus state for the search bar
    @FocusState private var isSearchFocused: Bool
    
    // Toast state
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            HStack(spacing: 0) {
                sidebar
                Divider()
                mainContent
            }
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .overlay(toastOverlay)
        // Key equivalents for navigation and actions
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Re-focus search when window appears
            isSearchFocused = true
            viewModel.fetchEntries()
        }
        .background(hiddenKeyboardShortcuts)
    }
    
    // MARK: - View Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TextField("Search Clipboard...", text: $viewModel.searchQuery)
                .font(.title2)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFocused)
                .onAppear {
                    isSearchFocused = true
                }
                .onSubmit {
                    viewModel.pasteSelected(autoPaste: false)
                }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
    }
    
    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(QuickAccessCategory.allCases) { category in
                    CategoryRow(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(8)
        }
        .frame(width: 160)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.entries.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No items found")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.entries.indices, id: \.self) { index in
                            QuickAccessItemWrapper(
                                viewModel: viewModel,
                                index: index,
                                handleDoubleTap: handleDoubleTap
                            )
                            .id(index)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: viewModel.selectedIndex) { oldValue, newIndex in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var toastOverlay: some View {
        Group {
            if showCopiedToast {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Copied")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .zIndex(1)
            }
        }
    }
    
    private var hiddenKeyboardShortcuts: some View {
        Group {
            Button("") { viewModel.moveSelectionUp() }
                .keyboardShortcut(.upArrow, modifiers: [])
                .opacity(0)
            
            Button("") { viewModel.moveSelectionDown() }
                .keyboardShortcut(.downArrow, modifiers: [])
                .opacity(0)
            
            Button("") { viewModel.pasteSelected(autoPaste: true) }
                .keyboardShortcut(.return, modifiers: [.command])
                .opacity(0)
                
            Button("") { viewModel.nextCategory() }
                .keyboardShortcut(.tab, modifiers: [])
                .opacity(0)
                
            Button("") { viewModel.previousCategory() }
                .keyboardShortcut(.tab, modifiers: [.shift])
                .opacity(0)
        }
    }
    
    // MARK: - Actions
    
    private func handleDoubleTap(at index: Int) {
        viewModel.selectedIndex = index
        viewModel.copyEntryWithoutHiding(at: index)
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showCopiedToast = false
            }
            QuickAccessWindowController.shared.hide()
        }
    }
}

// MARK: - Subviews

struct QuickAccessItemWrapper: View {
    @ObservedObject var viewModel: QuickAccessViewModel
    let index: Int
    let handleDoubleTap: (Int) -> Void
    
    var body: some View {
        QuickAccessItemRow(
            entry: viewModel.entries[index],
            isSelected: viewModel.selectedIndex == index,
            isLargeImageMode: viewModel.selectedCategory == .images,
            onCopy: { viewModel.copyEntry(at: index) },
            onDelete: { viewModel.deleteEntry(at: index) },
            onToggleFavorite: { viewModel.toggleFavorite(at: index) },
            onTogglePin: { viewModel.togglePin(at: index) },
            onSelect: { viewModel.selectedIndex = index },
            onDoubleTap: { handleDoubleTap(index) },
            onHover: { hovering in
                if hovering { viewModel.selectedIndex = index }
            }
        )
    }
}

struct CategoryRow: View {
    let category: QuickAccessCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.systemImage)
                    .frame(width: 20)
                Text(category.rawValue)
                    .font(.body)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAccessItemRow: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let isLargeImageMode: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onTogglePin: () -> Void
    let onSelect: () -> Void
    let onDoubleTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        HStack {
            // Pin Toggle on the left
            Button(action: onTogglePin) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(entry.isPinned ? .orange : (isSelected ? .white.opacity(0.6) : .secondary.opacity(0.3)))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 2)
            
            // Icon
            Image(systemName: entry.contentType.iconName)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 24)
            
            // Content Preview
            VStack(alignment: .leading, spacing: 2) {
                if let data = entry.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: isLargeImageMode ? 150 : 32)
                        .cornerRadius(isLargeImageMode ? 8 : 4)
                        .padding(.vertical, isLargeImageMode ? 8 : 2)
                } else if let text = entry.textContent {
                    Text(text)
                        .lineLimit(1)
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(isSelected ? .white : .primary)
                } else {
                    Text(entry.preview)
                        .lineLimit(1)
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(isSelected ? .white : .primary)
                        .italic()
                }
                
                Text(entry.sourceApp ?? "Unknown App")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Spacer()
            
            // Actions / Timestamp
            if isSelected {
                HStack(spacing: 12) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .foregroundColor(entry.isFavorite ? .yellow : .white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Favorite")
                    
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Copy")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete")
                }
            } else {
                HStack(spacing: 8) {
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onHover { hovering in
            onHover(hovering)
        }
        .onDrag {
            if let imageData = entry.imageData {
                let provider = NSItemProvider()
                // Provide TIFF or PNG representation (assuming TIFF is default for NSPasteboard image data, but let's provide public.image or specific)
                provider.registerDataRepresentation(forTypeIdentifier: UTType.image.identifier, visibility: .all) { completion in
                    completion(imageData, nil)
                    return nil
                }
                return provider
            } else if let text = entry.textContent {
                return NSItemProvider(object: text as NSString)
            }
            return NSItemProvider()
        }
    }
}

// MARK: - Visual Effect View for frosted glass
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
