//
//  ShortcutManager.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import KeyboardShortcuts
import SwiftUI
import AppKit

// MARK: - Shortcut Definitions

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.command, .control, .shift]))
    static let quickSearch = Self("quickSearch", default: .init(.space, modifiers: [.command, .control, .shift]))
    static let toggleQuickAccess = Self("toggleQuickAccess", default: .init(.space, modifiers: [.command, .shift]))
    static let quickPaste = Self("quickPaste", default: .init(.v, modifiers: [.command, .control, .option]))
    static let openSettings = Self("openSettings", default: .init(.comma, modifiers: [.command, .control, .shift]))
    static let openAI = Self("openAI", default: .init(.a, modifiers: [.command, .control, .shift]))
}

// MARK: - Shortcut Manager

/// Manages global keyboard shortcuts using the Carbon HotKey API via KeyboardShortcuts.
struct ShortcutManager {
    
    /// Registers the default keyboard shortcut handlers on app launch.
    @MainActor
    static func registerDefaults() {
        // Handler for toggling the main window
        KeyboardShortcuts.onKeyDown(for: .togglePanel) {
            NotificationCenter.default.post(name: .clipBToggleMainWindow, object: nil)
        }
        
        // Handler for quick search
        KeyboardShortcuts.onKeyDown(for: .quickSearch) {
            NotificationCenter.default.post(name: .clipBActivateSearch, object: nil)
        }
        
        // Handler for Quick Access Overlay
        KeyboardShortcuts.onKeyDown(for: .toggleQuickAccess) {
            NotificationCenter.default.post(name: .clipBToggleQuickAccess, object: nil)
        }
        
        // Handler for quick pasting the latest item
        KeyboardShortcuts.onKeyDown(for: .quickPaste) {
            NotificationCenter.default.post(name: .clipBQuickPasteLatest, object: nil)
        }
        
        // Handler for opening Settings
        KeyboardShortcuts.onKeyDown(for: .openSettings) {
            NotificationCenter.default.post(name: .clipBOpenSettings, object: nil)
        }
        
        // Handler for opening AI Assistant
        KeyboardShortcuts.onKeyDown(for: .openAI) {
            NotificationCenter.default.post(name: .clipBOpenAI, object: nil)
        }
    }
}

// MARK: - Custom Notifications

extension Notification.Name {
    static let clipBToggleMainWindow = Notification.Name("clipBToggleMainWindow")
    static let clipBActivateSearch = Notification.Name("clipBActivateSearch")
    static let clipBToggleQuickAccess = Notification.Name("clipBToggleQuickAccess")
    static let clipBQuickPasteLatest = Notification.Name("clipBQuickPasteLatest")
    static let clipBOpenSettings = Notification.Name("clipBOpenSettings")
    static let clipBOpenAI = Notification.Name("clipBOpenAI")
}
