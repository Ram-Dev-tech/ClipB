//
//  MenuBarView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    @Environment(\.openWindow) private var openWindow
    
    @State private var localSearchQuery = ""
    
    var filteredRecentEntries: [ClipboardEntry] {
        var results = viewModel.entries
        if !localSearchQuery.isEmpty {
            results = results.filter {
                $0.preview.localizedCaseInsensitiveContains(localSearchQuery) ||
                ($0.textContent?.localizedCaseInsensitiveContains(localSearchQuery) ?? false)
            }
        }
        return Array(results.prefix(10))
    }
    
    var recentFavorites: [ClipboardEntry] {
        Array(viewModel.entries.filter { $0.isFavorite }.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Search Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.clipBTextSecondary)
                TextField("Quick search...", text: $localSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.spacingS)
            .background(Color.clipBSurfaceElevated)
            .cornerRadius(DesignTokens.cornerRadiusSmall)
            .padding(DesignTokens.spacingM)
            
            Divider()
            
            // List Area
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    
                    // Recent Clipboard Items
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text("Recent Copies")
                            .sectionHeader()
                            .padding(.horizontal, DesignTokens.spacingM)
                        
                        if filteredRecentEntries.isEmpty {
                            Text("No recent entries")
                                .font(.system(size: 11))
                                .foregroundColor(.clipBTextSecondary)
                                .padding(.horizontal, DesignTokens.spacingM)
                                .padding(.vertical, DesignTokens.spacingS)
                        } else {
                            ForEach(filteredRecentEntries) { entry in
                                MenuBarEntryRow(entry: entry) {
                                    viewModel.copyToClipboard(entry)
                                }
                            }
                        }
                    }
                    
                    if !recentFavorites.isEmpty && localSearchQuery.isEmpty {
                        Divider()
                            .padding(.horizontal, DesignTokens.spacingM)
                        
                        // Recent Favorites
                        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                            Text("Starred Items")
                                .sectionHeader()
                                .padding(.horizontal, DesignTokens.spacingM)
                            
                            ForEach(recentFavorites) { entry in
                                MenuBarEntryRow(entry: entry) {
                                    viewModel.copyToClipboard(entry)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, DesignTokens.spacingM)
            }
            .frame(maxHeight: 320)
            
            Divider()
            
            // Footer Control Bar
            HStack(spacing: DesignTokens.spacingM) {
                Button(action: {
                    openWindow(id: "main")
                    appState.openMainWindow()
                }) {
                    Label("Dashboard", systemImage: "macwindow")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(SubtleButtonStyle())
                
                Spacer()
                
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(SubtleButtonStyle())
                .help("Settings")
                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .buttonStyle(SubtleButtonStyle())
                .help("Quit ClipB")
            }
            .padding(DesignTokens.spacingM)
            .background(Color.clipBSurfaceElevated.opacity(0.3))
        }
        .frame(width: 340)
        .background(.ultraThinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .clipBToggleMainWindow)) { _ in
            if appState.showingMainWindow {
                appState.showingMainWindow = false
            } else {
                openWindow(id: "main")
                appState.openMainWindow()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBActivateSearch)) { _ in
            openWindow(id: "main")
            appState.openMainWindow()
            appState.activateSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBClearAllHistory)) { _ in
            viewModel.clearHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBQuickPasteLatest)) { _ in
            if let latest = viewModel.entries.first {
                viewModel.copyToClipboard(latest)
            }
        }
    }
}

// MARK: - Menu Bar Entry Row

struct MenuBarEntryRow: View {
    let entry: ClipboardEntry
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacingS) {
                Image(systemName: entry.contentType.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(isHovered ? .clipBPrimary : .clipBTextSecondary)
                    .frame(width: 16)
                
                Text(entry.preview)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.clipBTextPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(entry.formattedTimestamp)
                    .font(.system(size: 9))
                    .foregroundColor(.clipBTextSecondary)
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.spacingS - 2)
            .background(isHovered ? Color.clipBPrimary.opacity(0.08) : Color.clear)
            .cornerRadius(DesignTokens.cornerRadiusSmall)
            .padding(.horizontal, DesignTokens.spacingS)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}
