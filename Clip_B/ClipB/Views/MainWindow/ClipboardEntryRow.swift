//
//  ClipboardEntryRow.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    @EnvironmentObject var collectionsViewModel: CollectionsViewModel
    
    @State private var isHovered = false
    
    var isSelected: Bool {
        appState.selectedEntryId == entry.id
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            // Content Type Icon/Badge
            CategoryBadge(type: entry.contentType)
            
            // Text Preview & Source App
            VStack(alignment: .leading, spacing: 2) {
                if let data = entry.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                        .cornerRadius(4)
                } else {
                    if let data = entry.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                        .cornerRadius(4)
                } else {
                    if let attrString = try? AttributedString(markdown: entry.preview, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attrString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .white : .clipBTextPrimary)
                            .lineLimit(2)
                    } else {
                        Text(entry.preview)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .white : .clipBTextPrimary)
                            .lineLimit(2)
                    }
                }
                }
                
                if let source = entry.sourceApp {
                    Text(source)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .clipBTextSecondary)
                }
            }
            
            Spacer()
            
            // Timestamp and Hover Quick Actions
            HStack(spacing: DesignTokens.spacingS) {
                if isHovered {
                    HStack(spacing: DesignTokens.spacingXS) {
                        QuickActionButton(iconName: "doc.on.doc", tooltip: "Copy Again") {
                            viewModel.copyToClipboard(entry)
                        }
                        
                        QuickActionButton(
                            iconName: entry.isFavorite ? "star.fill" : "star",
                            tooltip: entry.isFavorite ? "Remove from Favorites" : "Add to Favorites"
                        ) {
                            viewModel.toggleFavorite(entry)
                        }
                        
                        QuickActionButton(iconName: "trash", tooltip: "Delete", isDestructive: true) {
                            viewModel.deleteEntry(entry)
                        }
                    }
                } else {
                    Text(entry.formattedTimestamp)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .clipBTextSecondary)
                    
                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white : .clipBPrimary)
                    }
                    
                    if entry.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white : .orange)
                    }
                }
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
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                .stroke(isSelected ? Color.clear : Color.clipBBorder.opacity(0.5), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                appState.selectEntry(entry)
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(action: { viewModel.copyToClipboard(entry) }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button(action: { viewModel.toggleFavorite(entry) }) {
                Label(entry.isFavorite ? "Remove Favorite" : "Favorite", systemImage: "star")
            }
            
            Button(action: { viewModel.togglePin(entry) }) {
                Label(entry.isPinned ? "Unpin" : "Pin", systemImage: "pin")
            }
            
            Menu("Move to Collection") {
                Button("None") {
                    // Remove from collection
                    viewModel.moveToCollection(entry, collectionId: "")
                }
                ForEach(collectionsViewModel.collections) { col in
                    Button(col.name) {
                        viewModel.moveToCollection(entry, collectionId: col.id)
                    }
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: { viewModel.deleteEntry(entry) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
