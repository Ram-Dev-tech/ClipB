//
//  AppState.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import Combine
import AppKit

// MARK: - SidebarItem

/// Represents the primary navigation items displayed in the sidebar.
///
/// Each case maps to a distinct view within the main content area.
/// The enum provides display metadata (name, icon) for rendering.
enum SidebarItem: String, CaseIterable, Identifiable, Sendable {
    case home
    case clipboard
    case favorites
    case collections
    case images
    case code
    case ai
    case search
    case statistics
    case settings

    var id: String { rawValue }

    /// Human-readable display name for the sidebar label.
    var displayName: String {
        switch self {
        case .home:        return "Home"
        case .clipboard:   return "Clipboard"
        case .favorites:   return "Favorites"
        case .collections: return "Collections"
        case .images:      return "Images"
        case .code:        return "Code"
        case .ai:          return "AI"
        case .search:      return "Search"
        case .statistics:  return "Statistics"
        case .settings:    return "Settings"
        }
    }

    /// SF Symbol name used for the sidebar icon.
    var iconName: String {
        switch self {
        case .home:        return "house"
        case .clipboard:   return "clipboard"
        case .favorites:   return "star"
        case .collections: return "folder"
        case .images:      return "photo.on.rectangle"
        case .code:        return "chevron.left.forwardslash.chevron.right"
        case .ai:          return "brain"
        case .search:      return "magnifyingglass"
        case .statistics:  return "chart.bar"
        case .settings:    return "gear"
        }
    }
}

// MARK: - AppState

/// Central application state that drives navigation, entry selection,
/// search activation, and window lifecycle.
///
/// `AppState` is injected into the SwiftUI environment as an
/// `@EnvironmentObject` so that every view can observe and mutate
/// shared navigation state without tight coupling.
///
/// ## Usage
/// ```swift
/// @EnvironmentObject var appState: AppState
/// appState.selectedSidebarItem = .favorites
/// ```
@MainActor
final class AppState: ObservableObject {

    // MARK: - Navigation

    /// The currently selected sidebar item that determines which
    /// content view is displayed in the main area.
    @Published var selectedSidebarItem: SidebarItem = .home

    /// The ID of the currently selected clipboard entry, if any.
    /// Used to drive the detail pane in a master-detail layout.
    @Published var selectedEntryId: String?

    // MARK: - Search

    /// The current global search query string.
    @Published var searchQuery: String = ""

    /// Whether the search overlay / search bar is actively shown.
    @Published var isSearchActive: Bool = false

    // MARK: - Window

    /// Whether the main application window is currently visible.
    @Published var showingMainWindow: Bool = false

    // MARK: - Appearance

    /// Whether dark mode is currently active. Defaults to `true`
    /// and can be bound to system appearance or user preference.
    @Published var isDarkMode: Bool = true

    // MARK: - Initialization

    init() {
        // Derive initial dark-mode from the system appearance
        isDarkMode = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // MARK: - Public API

    /// Brings the main application window to the foreground and
    /// activates the app.
    ///
    /// Call this from the menu bar icon tap or global shortcut handler.
    func openMainWindow() {
        NSApp?.activate(ignoringOtherApps: true)
        showingMainWindow = true
    }

    /// Selects a clipboard entry and navigates to the clipboard view
    /// to display its detail.
    ///
    /// - Parameter entry: The `ClipboardEntry` to select.
    func selectEntry(_ entry: ClipboardEntry) {
        selectedEntryId = entry.id
        // Navigate to clipboard if we aren't already there
        if selectedSidebarItem != .clipboard {
            selectedSidebarItem = .clipboard
        }
    }

    /// Clears the current entry selection.
    func clearSelection() {
        selectedEntryId = nil
    }

    /// Activates the search interface with an optional initial query.
    ///
    /// - Parameter query: An optional initial search string.
    func activateSearch(query: String = "") {
        searchQuery = query
        isSearchActive = true
        selectedSidebarItem = .search
    }
}
