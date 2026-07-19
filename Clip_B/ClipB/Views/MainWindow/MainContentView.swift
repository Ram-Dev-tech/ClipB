//
//  MainContentView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var clipboardViewModel: ClipboardViewModel
    @EnvironmentObject var collectionsViewModel: CollectionsViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
        } detail: {
            Group {
                switch appState.selectedSidebarItem {
                case .home:
                    HomeView()
                case .clipboard:
                    ClipboardListView()
                case .favorites:
                    FavoritesView()
                case .collections:
                    CollectionsView()
                case .images:
                    ImagesView()
                case .code:
                    CodeView()
                case .ai:
                    // Phase 1 basic AI UI
                    PlaceholderAIView()
                case .search:
                    SearchView()
                case .statistics:
                    StatisticsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(minWidth: 600)
            .background(Color.clipBSurface)
        }
        .environment(\.colorScheme, appState.isDarkMode ? .dark : .light)
    }
}

// MARK: - AI View (Offline-First)

struct PlaceholderAIView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacingXL) {
                Spacer(minLength: DesignTokens.spacingXL)
                
                // Hero icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Smart Clipboard — No AI Required")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("ClipB automatically detects and categorizes everything you copy using built-in local detection. No internet, no API keys, no models needed.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.clipBTextSecondary)
                    .font(.body)
                    .padding(.horizontal, DesignTokens.spacingXXL)
                
                // Offline capabilities grid
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    Text("Built-in Detection (Always Active)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignTokens.spacingM),
                        GridItem(.flexible(), spacing: DesignTokens.spacingM),
                    ], spacing: DesignTokens.spacingM) {
                        capabilityCard(icon: "envelope.fill", title: "Emails", desc: "Detects email addresses", color: .blue)
                        capabilityCard(icon: "phone.fill", title: "Phone Numbers", desc: "International formats", color: .green)
                        capabilityCard(icon: "link", title: "URLs & Links", desc: "Websites, GitHub, etc.", color: .orange)
                        capabilityCard(icon: "chevron.left.forwardslash.chevron.right", title: "Code Snippets", desc: "20+ languages detected", color: .purple)
                        capabilityCard(icon: "paintpalette.fill", title: "Colors", desc: "Hex, RGB, HSL values", color: .pink)
                        capabilityCard(icon: "doc.richtext", title: "Rich Text", desc: "Markdown & formatting", color: .teal)
                        capabilityCard(icon: "tag.fill", title: "Auto-Tags", desc: "Smart categorization", color: .indigo)
                        capabilityCard(icon: "magnifyingglass", title: "Full-Text Search", desc: "Instant FTS5 search", color: .yellow)
                    }
                }
                .padding(.horizontal, DesignTokens.spacingXL)
                
                Divider()
                    .padding(.horizontal, DesignTokens.spacingXXL)
                
                // Optional AI section
                VStack(spacing: DesignTokens.spacingM) {
                    if settingsViewModel.aiEnabled {
                        Label("AI features are enabled", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Advanced features like summarization, translation, grammar correction, and code explanation are active via \(settingsViewModel.aiProvider.capitalized).")
                            .font(.callout)
                            .foregroundColor(.clipBTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.spacingXXL)
                    } else {
                        Label("Want more? AI is optional.", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundColor(.clipBTextSecondary)
                        
                        Text("Enable an AI provider in Settings for summarization, translation, grammar correction, and code explanation.")
                            .font(.callout)
                            .foregroundColor(.clipBTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.spacingXXL)
                        
                        Button(action: {
                            appState.selectedSidebarItem = .settings
                            settingsViewModel.selectedSettingsTab = .ai
                        }) {
                            Label("Configure AI in Settings", systemImage: "gear")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                
                Spacer(minLength: DesignTokens.spacingXL)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clipBSurface)
    }
    
    @ViewBuilder
    private func capabilityCard(icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.clipBTextSecondary)
            }
            
            Spacer()
        }
        .padding(DesignTokens.spacingM)
        .background(Color.clipBSurfaceElevated.opacity(0.6))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                .stroke(Color.clipBBorder.opacity(0.5), lineWidth: 1)
        )
    }
}
