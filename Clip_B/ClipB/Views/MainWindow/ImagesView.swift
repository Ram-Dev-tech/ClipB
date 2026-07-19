//
//  ImagesView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct ImagesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    var imageEntries: [ClipboardEntry] {
        viewModel.entries.filter { $0.contentType == .image || $0.contentType == .screenshot }
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: DesignTokens.spacingM)
    ]
    
    var body: some View {
        HSplitView {
            // Master Grid Pane
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("Image Gallery")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Text("\(imageEntries.count) images")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.clipBTextSecondary)
                        .padding(.horizontal, DesignTokens.spacingS)
                        .padding(.vertical, 2)
                        .background(Color.clipBSurfaceElevated)
                        .cornerRadius(DesignTokens.cornerRadiusSmall)
                }
                .padding(DesignTokens.spacingL)
                
                Divider()
                
                if imageEntries.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary)
                        Text("No Copied Images")
                            .font(.headline)
                        Text("Images and screenshots you copy will appear in this grid.")
                            .font(.subheadline)
                            .foregroundColor(.clipBTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(DesignTokens.spacingXXL)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
                            ForEach(imageEntries) { entry in
                                ImageGridItem(entry: entry)
                            }
                        }
                        .padding(DesignTokens.spacingL)
                    }
                }
            }
            .frame(minWidth: 350, idealWidth: 400, maxWidth: .infinity)
            
            // Detail Preview Pane
            Group {
                if let selectedId = appState.selectedEntryId,
                   let entry = viewModel.entries.first(where: { $0.id == selectedId }) {
                    DetailView(entry: entry)
                } else {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary.opacity(0.8))
                        Text("Select an image")
                            .font(.headline)
                        Text("Select any thumbnail to view full resolution and OCR.")
                            .font(.subheadline)
                            .foregroundColor(.clipBTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 350, maxWidth: .infinity)
        }
    }
}

// MARK: - Image Grid Item

struct ImageGridItem: View {
    let entry: ClipboardEntry
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    @State private var isHovered = false
    
    var isSelected: Bool {
        appState.selectedEntryId == entry.id
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                appState.selectEntry(entry)
            }
        }) {
            VStack(spacing: 0) {
                ZStack {
                    if let data = entry.imageData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    } else {
                        Color.clipBSurfaceElevated
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.clipBTextSecondary)
                            )
                    }
                    
                    if isHovered {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: { viewModel.copyToClipboard(entry) }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { viewModel.deleteEntry(entry) }) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                        .padding(4)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(4)
                        }
                        .background(Color.black.opacity(0.15))
                    }
                }
                .cornerRadius(DesignTokens.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .stroke(isSelected ? Color.clipBPrimary : Color.clipBBorder, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? Color.clipBPrimary.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
