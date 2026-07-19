//
//  SidebarView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var clipboardViewModel: ClipboardViewModel
    @EnvironmentObject var statisticsViewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Header
            HStack(spacing: DesignTokens.spacingS) {
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("ClipB")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("The smartest clipboard")
                        .font(.system(size: 9))
                        .foregroundColor(.clipBTextSecondary)
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingXL)
            .padding(.bottom, DesignTokens.spacingL)
            
            Divider()
                .padding(.horizontal, DesignTokens.spacingL)
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                    // SECTION: Dashboard
                    SidebarSection(title: "Dashboard") {
                        SidebarRow(item: .home)
                    }
                    
                    // SECTION: Library
                    SidebarSection(title: "Library") {
                        SidebarRow(item: .clipboard, badgeCount: clipboardViewModel.entryCount)
                        SidebarRow(item: .favorites, badgeCount: statisticsViewModel.favoriteCount)
                        SidebarRow(item: .collections)
                        SidebarRow(item: .images)
                        SidebarRow(item: .code)
                    }
                    
                    // SECTION: Tools
                    SidebarSection(title: "Tools") {
                        SidebarRow(item: .ai)
                        SidebarRow(item: .search)
                    }
                    
                    // SECTION: Insights
                    SidebarSection(title: "Insights") {
                        SidebarRow(item: .statistics)
                    }
                }
                .padding(.vertical, DesignTokens.spacingL)
            }
            
            Spacer()
            
            // Settings Footer
            Divider()
                .padding(.horizontal, DesignTokens.spacingL)
            
            SidebarRow(item: .settings)
                .padding(.horizontal, DesignTokens.spacingM)
                .padding(.vertical, DesignTokens.spacingS)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Sidebar Section

struct SidebarSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
            Text(title)
                .sectionHeader()
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.bottom, 2)
            
            content
        }
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let item: SidebarItem
    var badgeCount: Int? = nil
    
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false
    
    var isSelected: Bool {
        appState.selectedSidebarItem == item
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                appState.selectedSidebarItem = item
            }
        }) {
            HStack(spacing: DesignTokens.spacingM) {
                Image(systemName: item.iconName)
                    .font(.system(size: DesignTokens.iconSizeMedium))
                    .foregroundColor(isSelected ? .white : .clipBTextSecondary)
                    .frame(width: 20)
                
                Text(item.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .clipBTextPrimary)
                
                Spacer()
                
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.clipBPrimary.opacity(0.15))
                        .foregroundColor(isSelected ? .white : .clipBPrimary)
                        .cornerRadius(DesignTokens.cornerRadiusSmall)
                }
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.spacingS)
            .background(
                isSelected 
                ? AnyShapeStyle(LinearGradient(
                    gradient: Gradient(colors: [Color.clipBGradientStart, Color.clipBGradientEnd]),
                    startPoint: .leading,
                    endPoint: .trailing
                  ))
                : AnyShapeStyle(isHovered ? Color.clipBPrimary.opacity(0.1) : Color.clear)
            )
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .padding(.horizontal, DesignTokens.spacingM)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
