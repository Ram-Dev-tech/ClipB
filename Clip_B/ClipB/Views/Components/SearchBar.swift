//
//  SearchBar.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct SearchBar: View {
    @EnvironmentObject var viewModel: ClipboardViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingS) {
            // Search Input Field
            HStack(spacing: DesignTokens.spacingS) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.clipBTextSecondary)
                    .font(.system(size: DesignTokens.iconSizeMedium))
                
                TextField("Search clipboard history...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .font(.system(size: 14))
                    .foregroundColor(.clipBTextPrimary)
                    .onSubmit {
                        viewModel.search(viewModel.searchQuery)
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        viewModel.search("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.clipBTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.spacingS)
            .background(Color.clipBSurfaceElevated)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                    .stroke(isFocused ? Color.clipBPrimary : Color.clipBBorder, lineWidth: 1.5)
            )
            .shadow(color: isFocused ? Color.clipBPrimary.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
            .animation(.easeOut(duration: 0.2), value: isFocused)
            
            // Content Type Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.spacingS) {
                    // "All" Chip
                    FilterChip(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: viewModel.selectedContentType == nil,
                        color: .clipBPrimary
                    ) {
                        viewModel.filterByType(nil)
                    }
                    
                    ForEach(ContentType.allCases) { type in
                        let color = colorForType(type)
                        FilterChip(
                            title: type.displayName,
                            icon: type.iconName,
                            isSelected: viewModel.selectedContentType == type,
                            color: color
                        ) {
                            viewModel.filterByType(type)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
    
    private func colorForType(_ type: ContentType) -> Color {
        switch type.accentColor {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        default: return .clipBPrimary
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.spacingXS + 2)
            .background(
                isSelected 
                ? color.opacity(0.2) 
                : (isHovered ? Color.clipBSurfaceElevated : Color.clipBSurfaceElevated.opacity(0.5))
            )
            .foregroundColor(isSelected ? color : .clipBTextPrimary)
            .cornerRadius(DesignTokens.cornerRadiusXL)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXL)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clipBBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
