//
//  CollectionsView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var viewModel: ClipboardViewModel
    @EnvironmentObject var collectionsViewModel: CollectionsViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 140), spacing: DesignTokens.spacingM)
    ]
    
    var body: some View {
        HSplitView {
            // Master Collection Grid Pane
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "folder")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Button(action: {
                        collectionsViewModel.isCreatingNew = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.clipBPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(DesignTokens.spacingL)
                
                Divider()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
                        ForEach(collectionsViewModel.collections) { col in
                            CollectionCard(collection: col)
                        }
                        
                        // Add collection trigger button card
                        Button(action: {
                            collectionsViewModel.isCreatingNew = true
                        }) {
                            VStack(spacing: DesignTokens.spacingS) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.clipBTextSecondary)
                                Text("New Collection")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.clipBTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color.clipBSurfaceElevated.opacity(0.4))
                            .cornerRadius(DesignTokens.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                    .stroke(Color.clipBBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(DesignTokens.spacingL)
                }
            }
            .frame(minWidth: 350, idealWidth: 400, maxWidth: .infinity)
            
            // Detail Items in Selected Collection Pane
            Group {
                if let selected = collectionsViewModel.selectedCollection {
                    CollectionItemsList(collection: selected)
                } else {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary.opacity(0.8))
                        Text("Select a Collection")
                            .font(.headline)
                        Text("Select any folder to view organize items inside.")
                            .font(.subheadline)
                            .foregroundColor(.clipBTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 350, maxWidth: .infinity)
        }
        .sheet(isPresented: $collectionsViewModel.isCreatingNew) {
            createCollectionSheet()
        }
    }
    
    // MARK: - Subviews
    
    private func createCollectionSheet() -> some View {
        VStack(spacing: DesignTokens.spacingL) {
            Text("Create Collection")
                .font(.headline)
            
            Form {
                TextField("Collection Name", text: $collectionsViewModel.newCollectionName)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Icon", selection: $collectionsViewModel.newCollectionIcon) {
                    Image(systemName: "folder").tag("folder")
                    Image(systemName: "briefcase").tag("briefcase")
                    Image(systemName: "book").tag("book")
                    Image(systemName: "heart").tag("heart")
                    Image(systemName: "tag").tag("tag")
                    Image(systemName: "star").tag("star")
                }
                
                Picker("Color", selection: $collectionsViewModel.newCollectionColor) {
                    Text("Blue").tag("blue")
                    Text("Red").tag("red")
                    Text("Green").tag("green")
                    Text("Purple").tag("purple")
                    Text("Orange").tag("orange")
                }
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    collectionsViewModel.isCreatingNew = false
                }
                .buttonStyle(SubtleButtonStyle())
                
                Spacer()
                
                Button("Create") {
                    collectionsViewModel.createCollection()
                }
                .buttonStyle(PremiumButtonStyle())
                .disabled(collectionsViewModel.newCollectionName.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 300, height: 220)
    }
}

// MARK: - Collection Card Component

struct CollectionCard: View {
    let collection: Collection
    
    @EnvironmentObject var collectionsViewModel: CollectionsViewModel
    @State private var isHovered = false
    
    var isSelected: Bool {
        collectionsViewModel.selectedCollection?.id == collection.id
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                collectionsViewModel.selectCollection(collection)
            }
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack {
                    Image(systemName: collection.icon)
                        .font(.system(size: 20))
                        .foregroundColor(colorForName(collection.colorName))
                    
                    Spacer()
                    
                    Text("\(collection.itemCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.clipBTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.clipBSurfaceElevated)
                        .clipShape(Capsule())
                }
                
                Text(collection.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.clipBTextPrimary)
                    .lineLimit(1)
            }
            .padding(DesignTokens.spacingM)
            .frame(height: 100)
            .background(
                isSelected 
                ? Color.clipBPrimary.opacity(0.15) 
                : (isHovered ? Color.clipBPrimary.opacity(0.08) : Color.clipBSurfaceElevated.opacity(0.3))
            )
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                    .stroke(isSelected ? Color.clipBPrimary : Color.clipBBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(role: .destructive, action: {
                collectionsViewModel.deleteCollection(collection)
            }) {
                Label("Delete Collection", systemImage: "trash")
            }
        }
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }
}

// MARK: - Collection Items List Component

struct CollectionItemsList: View {
    let collection: Collection
    
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    var items: [ClipboardEntry] {
        viewModel.entries.filter { $0.collectionId == collection.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: collection.icon)
                    .foregroundColor(.clipBPrimary)
                Text(collection.name)
                    .font(.headline)
                
                Spacer()
                Text("\(items.count) entries")
                    .font(.system(size: 11))
                    .foregroundColor(.clipBTextSecondary)
            }
            .padding(DesignTokens.spacingL)
            
            Divider()
            
            if items.isEmpty {
                VStack(spacing: DesignTokens.spacingM) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.clipBTextSecondary)
                    Text("This collection is empty.")
                        .foregroundColor(.clipBTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items) { entry in
                    ClipboardEntryRow(entry: entry)
                }
                .listStyle(.sidebar)
            }
        }
    }
}
