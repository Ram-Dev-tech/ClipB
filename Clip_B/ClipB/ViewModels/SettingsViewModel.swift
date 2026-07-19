//
//  SettingsViewModel.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import AppKit

// MARK: - SettingsViewModel

/// Manages all user-configurable settings for ClipB.
///
/// Persistent state is stored via `@AppStorage` backed by
/// `UserDefaults`. The view model also provides utility methods
/// for database import/export and size calculation.
///
/// ## Tabs
/// Settings are organised into tabs represented by `SettingsTab`.
/// Each tab has an associated SF Symbol for navigation.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Persisted Settings (AppStorage)

    /// Maximum number of clipboard entries to retain in the database.
    @AppStorage("clipboardHistoryLimit") var historyLimit: Int = 10_000

    /// How frequently (in seconds) the clipboard monitor polls
    /// `NSPasteboard` for changes.
    @AppStorage("pollingInterval") var pollingInterval: Double = 0.5

    /// Whether ClipB should launch automatically at login.
    @AppStorage("launchAtStartup") var launchAtStartup: Bool = false
    
    /// Whether to automatically check for updates.
    @AppStorage("autoUpdateEnabled") var autoUpdateEnabled: Bool = true

    /// Whether to show system notifications on new clipboard captures.
    @AppStorage("showNotifications") var showNotifications: Bool = true

    /// Whether AI features are enabled. When `false` the app runs
    /// completely offline using only local regex-based categorization.
    @AppStorage("aiEnabled") var aiEnabled: Bool = false

    /// The AI inference provider (e.g. "openrouter", "openai", "local").
    @AppStorage("aiProvider") var aiProvider: String = "openrouter"

    /// API key for the selected AI provider.
    @AppStorage("aiApiKey") var aiApiKey: String = ""

    /// Custom endpoint URL for the AI provider (empty = default).
    @AppStorage("aiEndpoint") var aiEndpoint: String = ""

    /// The model identifier string (e.g. "gpt-4o", "claude-sonnet-4-20250514").
    @AppStorage("aiModelName") var aiModelName: String = ""

    /// Sampling temperature for AI inference (0.0 = deterministic, 2.0 = creative).
    @AppStorage("aiTemperature") var aiTemperature: Double = 0.7

    /// Whether to automatically summarize long clipboard entries.
    @AppStorage("aiAutoSummarize") var aiAutoSummarize: Bool = true

    /// Whether to automatically tag & categorize new entries.
    @AppStorage("aiAutoTag") var aiAutoTag: Bool = true

    /// Whether to auto-generate titles for code snippets.
    @AppStorage("aiAutoTitle") var aiAutoTitle: Bool = false

    /// Whether to run OCR text extraction for pasted images.
    @AppStorage("aiAutoOCR") var aiAutoOCR: Bool = true

    /// Whether to exclude password manager content from capture.
    @AppStorage("excludePasswordManagers") var excludePasswordManagers: Bool = true

    /// The current appearance theme: "system", "light", or "dark".
    @AppStorage("selectedTheme") var selectedTheme: String = "system"

    /// The filesystem path to the GRDB database file.
    @AppStorage("databasePath") var databasePath: String = ""

    /// Period for filtering entries in Quick Access "Recent" category.
    @AppStorage("quickAccessRecentPeriod") var quickAccessRecentPeriod: String = "week"

    // MARK: - Published State

    /// The currently selected settings tab.
    @Published var selectedSettingsTab: SettingsTab = .general

    // MARK: - SettingsTab

    /// Enumerates the available settings sections.
    enum SettingsTab: String, CaseIterable, Identifiable, Sendable {
        case general
        case appearance
        case ai
        case clipboard
        case shortcuts
        case privacy
        case database
        case about

        var id: String { rawValue }

        /// Human-readable tab title.
        var displayName: String { rawValue.capitalized }

        /// SF Symbol name for the tab icon.
        var iconName: String {
            switch self {
            case .general:    return "gear"
            case .appearance: return "paintbrush"
            case .ai:         return "brain"
            case .clipboard:  return "clipboard"
            case .shortcuts:  return "command"
            case .privacy:    return "lock.shield"
            case .database:   return "externaldrive"
            case .about:      return "info.circle"
            }
        }
    }

    // MARK: - Public API

    /// Resets all settings to their factory defaults.
    func resetToDefaults() {
        historyLimit = 10_000
        pollingInterval = 0.5
        launchAtStartup = false
        autoUpdateEnabled = true
        showNotifications = true
        aiEnabled = false
        aiProvider = "openrouter"
        aiApiKey = ""
        aiEndpoint = ""
        aiModelName = ""
        aiTemperature = 0.7
        aiAutoSummarize = true
        aiAutoTag = true
        aiAutoTitle = false
        aiAutoOCR = true
        excludePasswordManagers = true
        selectedTheme = "system"
        quickAccessRecentPeriod = "week"
        selectedSettingsTab = .general
    }

    /// Presents an `NSSavePanel` for the user to choose where to
    /// export a copy of the database file.
    func exportDatabase() {
        let panel = NSSavePanel()
        panel.title = "Export ClipB Database"
        panel.nameFieldStringValue = "ClipB_Backup.sqlite"
        panel.allowedContentTypes = [.database]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return
        }

        do {
            let sourceURL = databaseURL()
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            print("[ClipB] Database exported to \(destinationURL.path)")
        } catch {
            print("[ClipB] Error exporting database: \(error.localizedDescription)")
        }
    }

    /// Presents an `NSOpenPanel` for the user to select a database
    /// file to import, replacing the current one.
    func importDatabase() {
        let panel = NSOpenPanel()
        panel.title = "Import ClipB Database"
        panel.allowedContentTypes = [.database]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        do {
            let destinationURL = databaseURL()
            // Back up existing database first
            let backupURL = destinationURL.deletingLastPathComponent()
                .appendingPathComponent("ClipB_PreImport_Backup.sqlite")
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: backupURL)
                try FileManager.default.copyItem(at: destinationURL, to: backupURL)
            }
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            print("[ClipB] Database imported from \(sourceURL.path)")
        } catch {
            print("[ClipB] Error importing database: \(error.localizedDescription)")
        }
    }

    /// Returns a human-readable string representing the current
    /// database file size (e.g. "12.4 MB").
    func getDatabaseSize() -> String {
        let url = databaseURL()
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(
                    fromByteCount: fileSize,
                    countStyle: .file
                )
            }
        } catch {
            print("[ClipB] Error reading database size: \(error.localizedDescription)")
        }
        return "Unknown"
    }

    // MARK: - Private Helpers

    /// Resolves the URL of the active GRDB database file.
    ///
    /// Falls back to the default Application Support location
    /// when `databasePath` is empty.
    private func databaseURL() -> URL {
        if !databasePath.isEmpty {
            return URL(fileURLWithPath: databasePath)
        }
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("ClipB", isDirectory: true)
            .appendingPathComponent("ClipB.sqlite")
    }
}
