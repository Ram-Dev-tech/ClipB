//
//  FavoritesView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    var favoriteEntries: [ClipboardEntry] {
        viewModel.entries.filter { $0.isFavorite }
    }
    
    var body: some View {
        HSplitView {
            // Master List Pane
            VStack(spacing: 0) {
                // Header Title Card
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Text("\(favoriteEntries.count) items")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.clipBTextSecondary)
                        .padding(.horizontal, DesignTokens.spacingS)
                        .padding(.vertical, 2)
                        .background(Color.clipBSurfaceElevated)
                        .cornerRadius(DesignTokens.cornerRadiusSmall)
                }
                .padding(DesignTokens.spacingL)
                
                Divider()
                
                // List of Favorites
                if favoriteEntries.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "star")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary)
                        Text("No Favorite Items")
                            .font(.headline)
                        Text("Star items in history to pin them here permanently.")
                            .font(.subheadline)
                            .foregroundColor(.clipBTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(DesignTokens.spacingXXL)
                } else {
                    List(favoriteEntries) { entry in
                        ClipboardEntryRow(entry: entry)
                    }
                    .listStyle(.sidebar)
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
                        Image(systemName: "star.bubble")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary.opacity(0.8))
                        Text("Select a favorite")
                            .font(.headline)
                        Text("Select any starred item to preview details.")
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
