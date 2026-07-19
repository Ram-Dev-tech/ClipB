//
//  HomeView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var clipboardViewModel: ClipboardViewModel
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    @EnvironmentObject var collectionsViewModel: CollectionsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXXL) {
                // Header Welcome Banner
                headerSection()
                
                // Stats Cards Grid
                statsGridSection()
                
                // Pinned Items Section (if any)
                let pinnedEntries = clipboardViewModel.entries.filter { $0.isPinned }
                if !pinnedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.clipBPrimary)
                            Text("Pinned Items")
                                .sectionHeader()
                        }
                        
                        VStack(spacing: DesignTokens.spacingS) {
                            ForEach(pinnedEntries.prefix(5)) { entry in
                                ClipboardEntryRow(entry: entry)
                            }
                        }
                    }
                }
                
                // Recent Entries Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.clipBTextSecondary)
                        Text("Recent History")
                            .sectionHeader()
                    }
                    
                    if clipboardViewModel.entries.isEmpty {
                        Text("Clipboard is empty.")
                            .foregroundColor(.clipBTextSecondary)
                            .padding(.vertical, DesignTokens.spacingM)
                    } else {
                        VStack(spacing: DesignTokens.spacingS) {
                            ForEach(clipboardViewModel.entries.prefix(5)) { entry in
                                ClipboardEntryRow(entry: entry)
                            }
                        }
                    }
                }
                
                // Quick Actions Section
                quickActionsSection()
            }
            .padding(DesignTokens.spacingXXL)
        }
        .onAppear {
            statisticsViewModel.refresh()
        }
    }
    
    // MARK: - Subviews
    
    private func headerSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
            Text("Welcome to ClipB")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("The smartest clipboard you'll ever use.")
                .font(.subheadline)
                .foregroundColor(.clipBTextSecondary)
        }
    }
    
    private func statsGridSection() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: DesignTokens.spacingL),
            GridItem(.flexible(), spacing: DesignTokens.spacingL)
        ]
        
        return LazyVGrid(columns: columns, spacing: DesignTokens.spacingL) {
            StatCard(
                title: "Today's Copies",
                value: "\(statisticsViewModel.todayCopies)",
                icon: "doc.on.doc.fill",
                color: .blue
            )
            
            StatCard(
                title: "Total History Items",
                value: "\(statisticsViewModel.totalEntries)",
                icon: "history",
                color: .green
            )
            
            StatCard(
                title: "Favorites Pinned",
                value: "\(statisticsViewModel.favoriteCount)",
                icon: "star.fill",
                color: .orange
            )
            
            StatCard(
                title: "Database Storage",
                value: statisticsViewModel.storageUsed,
                icon: "arrow.down.circle.fill",
                color: .purple
            )
        }
    }
    
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("Quick Actions")
                .sectionHeader()
            
            HStack(spacing: DesignTokens.spacingL) {
                QuickActionButtonBig(title: "Search History", icon: "magnifyingglass") {
                    withAnimation {
                        appState.selectedSidebarItem = .search
                    }
                }
                
                QuickActionButtonBig(title: "New Collection", icon: "folder.badge.plus") {
                    withAnimation {
                        appState.selectedSidebarItem = .collections
                        collectionsViewModel.isCreatingNew = true
                    }
                }
                
                QuickActionButtonBig(title: "Open Settings", icon: "gear") {
                    withAnimation {
                        appState.selectedSidebarItem = .settings
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding(DesignTokens.spacingM)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.clipBTextPrimary)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.clipBTextSecondary)
            }
            Spacer()
        }
        .glassCard()
    }
}

// MARK: - Quick Action Big Button Component

struct QuickActionButtonBig: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.spacingS) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.spacingL)
            .background(isHovered ? Color.clipBPrimary.opacity(0.12) : Color.clipBSurfaceElevated.opacity(0.4))
            .foregroundColor(isHovered ? Color.clipBPrimary : Color.clipBTextPrimary)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                    .stroke(isHovered ? Color.clipBPrimary.opacity(0.3) : Color.clipBBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
