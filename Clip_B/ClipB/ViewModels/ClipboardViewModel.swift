//
//  ClipboardViewModel.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import Combine
import AppKit
import GRDB

// MARK: - ClipboardViewModel

/// The primary view model for ClipB, responsible for managing the
/// clipboard entry lifecycle including real-time monitoring,
/// full-text search, content-type filtering, pagination, and all
/// CRUD operations against the local database.
///
/// ## Architecture
/// - Subscribes to `ClipboardMonitor.lastEntry` to receive new
///   clipboard captures in real time.
/// - Debounces search input by 300 ms to avoid excessive queries.
/// - Groups entries into `TimelineSection` buckets for the timeline view.
/// - Supports infinite-scroll pagination with configurable page size.
///
/// ## Concurrency
/// All published state lives on `@MainActor`. Database I/O is
/// dispatched through `DatabaseManager.shared` which handles its
/// own concurrency via GRDB's `DatabasePool`.
@MainActor
final class ClipboardViewModel: ObservableObject {

    // MARK: - Published State

    /// All loaded clipboard entries in reverse-chronological order.
    @Published var entries: [ClipboardEntry] = []

    /// Entries after applying the current search query and content-type filter.
    @Published var filteredEntries: [ClipboardEntry] = []

    /// Entries grouped by timeline section for the timeline view.
    @Published var groupedEntries: [(TimelineSection, [ClipboardEntry])] = []

    /// Whether a data-loading operation is currently in progress.
    @Published var isLoading: Bool = false

    /// The current search query. Changes are debounced and trigger
    /// a new filtered fetch.
    @Published var searchQuery: String = ""

    /// Optional content-type filter. `nil` means "show all types".
    @Published var selectedContentType: ContentType?

    /// Total number of entries in the database (used for UI badges).
    @Published var entryCount: Int = 0

    // MARK: - Private State

    /// The clipboard monitor that polls `NSPasteboard` for changes.
    private let monitor = ClipboardMonitor()

    /// Active Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Current pagination offset.
    private var currentOffset: Int = 0

    /// Number of entries to fetch per page.
    private let pageSize: Int = 50

    /// Flag to temporarily suppress monitoring while we write
    /// back to the pasteboard (avoids re-capturing our own paste).
    private var isPaused: Bool = false

    // MARK: - Initialization

    init() {
        setupBindings()
        loadEntries()
        startMonitoring()
    }

    // MARK: - Public API – Monitoring

    /// Starts the clipboard monitor so new copies are captured.
    func startMonitoring() {
        monitor.startMonitoring()
    }

    /// Stops the clipboard monitor.
    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    // MARK: - Public API – Data Loading

    /// Performs the initial load of clipboard entries from the database.
    ///
    /// Resets the pagination offset and replaces the current entries array.
    func loadEntries() {
        isLoading = true
        currentOffset = 0

        do {
            let fetched = try DatabaseManager.shared.fetchEntries(
                limit: pageSize,
                offset: 0,
                contentType: selectedContentType,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            entries = fetched
            filteredEntries = fetched
            entryCount = try DatabaseManager.shared.entryCount()
            groupEntriesByTimeline()
        } catch {
            print("[ClipB] Error loading entries: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads the next page of entries and appends them to the
    /// existing list (infinite scroll).
    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        currentOffset += pageSize

        do {
            let moreEntries = try DatabaseManager.shared.fetchEntries(
                limit: pageSize,
                offset: currentOffset,
                contentType: selectedContentType,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            guard !moreEntries.isEmpty else {
                isLoading = false
                return
            }
            entries.append(contentsOf: moreEntries)
            filteredEntries = entries
            groupEntriesByTimeline()
        } catch {
            print("[ClipB] Error loading more entries: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Public API – Search & Filter

    /// Executes a full-text search against the database.
    ///
    /// - Parameter query: The search string. An empty string
    ///   resets to the unfiltered list.
    func search(_ query: String) {
        searchQuery = query
        loadEntries()
    }

    /// Filters visible entries by content type.
    ///
    /// - Parameter type: The `ContentType` to filter by, or `nil`
    ///   to remove the filter and show all types.
    func filterByType(_ type: ContentType?) {
        selectedContentType = type
        loadEntries()
    }

    // MARK: - Public API – Entry Actions

    /// Permanently deletes an entry from the database and removes
    /// it from the in-memory arrays.
    ///
    /// - Parameter entry: The entry to delete.
    func deleteEntry(_ entry: ClipboardEntry) {
        do {
            try DatabaseManager.shared.deleteEntry(id: entry.id)
            entries.removeAll { $0.id == entry.id }
            filteredEntries.removeAll { $0.id == entry.id }
            entryCount = max(0, entryCount - 1)
            groupEntriesByTimeline()
        } catch {
            print("[ClipB] Error deleting entry \(entry.id): \(error.localizedDescription)")
        }
    }

    /// Toggles the favorite status of an entry.
    ///
    /// - Parameter entry: The entry to toggle.
    func toggleFavorite(_ entry: ClipboardEntry) {
        do {
            try DatabaseManager.shared.toggleFavorite(id: entry.id)
            refreshEntries()
        } catch {
            print("[ClipB] Error toggling favorite for \(entry.id): \(error.localizedDescription)")
        }
    }

    /// Toggles the pinned status of an entry.
    ///
    /// - Parameter entry: The entry to toggle.
    func togglePin(_ entry: ClipboardEntry) {
        do {
            try DatabaseManager.shared.togglePin(id: entry.id)
            refreshEntries()
        } catch {
            print("[ClipB] Error toggling pin for \(entry.id): \(error.localizedDescription)")
        }
    }

    /// Copies the entry's content back to the system pasteboard.
    ///
    /// Monitoring is temporarily paused so the paste-back is not
    /// re-captured as a new entry.
    ///
    /// - Parameter entry: The entry whose content to copy.
    func copyToClipboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Pause monitoring to avoid re-capturing our own write
        isPaused = true
        monitor.stopMonitoring()

        switch entry.contentType {
        case .image, .screenshot:
            if let imageData = entry.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        case .url:
            if let text = entry.textContent, let url = URL(string: text) {
                pasteboard.writeObjects([url as NSURL])
            } else if let text = entry.textContent {
                pasteboard.setString(text, forType: .string)
            }
        default:
            if let text = entry.textContent {
                pasteboard.setString(text, forType: .string)
            }
        }

        // Resume monitoring after a short delay so the pasteboard
        // change count can settle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPaused = false
            self?.monitor.startMonitoring()
        }
    }

    /// Moves an entry into the specified collection.
    ///
    /// - Parameters:
    ///   - entry: The entry to move.
    ///   - collectionId: The target collection's ID.
    func moveToCollection(_ entry: ClipboardEntry, collectionId: String) {
        do {
            try DatabaseManager.shared.moveToCollection(entryId: entry.id, collectionId: collectionId.isEmpty ? nil : collectionId)
            refreshEntries()
        } catch {
            print("[ClipB] Error moving entry \(entry.id) to collection \(collectionId): \(error.localizedDescription)")
        }
    }

    /// Deletes **all** clipboard history entries from the database.
    func clearHistory() {
        do {
            // Delete every entry currently loaded, then re-fetch
            for entry in entries {
                try DatabaseManager.shared.deleteEntry(id: entry.id)
            }
            entries.removeAll()
            filteredEntries.removeAll()
            groupedEntries.removeAll()
            entryCount = 0
            currentOffset = 0
        } catch {
            print("[ClipB] Error clearing history: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    /// Sets up Combine pipelines for reactive state management.
    ///
    /// 1. Subscribes to the monitor's `lastEntry` publisher so new
    ///    captures are automatically prepended to the list.
    /// 2. Debounces `searchQuery` changes by 300 ms and triggers
    ///    a fresh database query.
    private func setupBindings() {
        // React to new clipboard entries from the monitor
        monitor.$lastEntry
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEntry in
                guard let self, !self.isPaused else { return }

                // Insert at the beginning (most recent first)
                self.entries.insert(newEntry, at: 0)
                self.filteredEntries.insert(newEntry, at: 0)
                self.entryCount += 1
                self.groupEntriesByTimeline()
            }
            .store(in: &cancellables)

        // Debounced search: wait 300ms after the user stops typing
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                self.loadEntries()
            }
            .store(in: &cancellables)
    }

    /// Groups `filteredEntries` by their `TimelineSection` and
    /// updates `groupedEntries` for the timeline view.
    ///
    /// Entries are first sorted in reverse-chronological order,
    /// then bucketed by section. Sections themselves are ordered
    /// from most recent to oldest.
    private func groupEntriesByTimeline() {
        let sorted = filteredEntries.sorted { $0.timestamp > $1.timestamp }

        var dict: [TimelineSection: [ClipboardEntry]] = [:]
        for entry in sorted {
            let section = entry.timelineSection
            dict[section, default: []].append(entry)
        }

        // Define the canonical section ordering
        let sectionOrder: [TimelineSection] = [
            .today, .yesterday, .lastWeek, .lastMonth, .older
        ]

        groupedEntries = sectionOrder.compactMap { section in
            guard let items = dict[section], !items.isEmpty else { return nil }
            return (section, items)
        }
    }

    /// Reloads entries from the database without resetting the
    /// pagination offset. Used after in-place mutations like
    /// toggling favorites or pins.
    private func refreshEntries() {
        do {
            let fetched = try DatabaseManager.shared.fetchEntries(
                limit: currentOffset + pageSize,
                offset: 0,
                contentType: selectedContentType,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            entries = fetched
            filteredEntries = fetched
            entryCount = try DatabaseManager.shared.entryCount()
            groupEntriesByTimeline()
        } catch {
            print("[ClipB] Error refreshing entries: \(error.localizedDescription)")
        }
    }
}
