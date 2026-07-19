//
//  SearchView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    @State private var showFilters = false
    @State private var favoritesOnly = false
    @State private var pinnedOnly = false
    
    var filteredResults: [ClipboardEntry] {
        var results = viewModel.entries
        
        // Filter by Search Query (if not empty)
        if !viewModel.searchQuery.isEmpty {
            results = results.filter { entry in
                entry.preview.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                (entry.textContent?.localizedCaseInsensitiveContains(viewModel.searchQuery) ?? false)
            }
        }
        
        // Filter by Type
        if let selectedType = viewModel.selectedContentType {
            results = results.filter { $0.contentType == selectedType }
        }
        
        // Filter by Favorites Only
        if favoritesOnly {
            results = results.filter { $0.isFavorite }
        }
        
        // Filter by Pinned Only
        if pinnedOnly {
            results = results.filter { $0.isPinned }
        }
        
        return results
    }
    
    var body: some View {
        HSplitView {
            // Master Search List Pane
            VStack(spacing: 0) {
                // Search input with filter toggles
                VStack(spacing: DesignTokens.spacingS) {
                    SearchBar()
                    
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showFilters.toggle()
                            }
                        }) {
                            Label("Advanced Filters", systemImage: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(showFilters ? .clipBPrimary : .clipBTextSecondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("\(filteredResults.count) matches")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.clipBTextSecondary)
                            .padding(.horizontal, DesignTokens.spacingS)
                            .padding(.vertical, 2)
                            .background(Color.clipBSurfaceElevated)
                            .cornerRadius(DesignTokens.cornerRadiusSmall)
                    }
                    .padding(.top, 4)
                    
                    if showFilters {
                        HStack(spacing: DesignTokens.spacingM) {
                            Toggle("Favorites Only", isOn: $favoritesOnly)
                                .toggleStyle(.checkbox)
                                .font(.system(size: 11))
                            
                            Toggle("Pinned Only", isOn: $pinnedOnly)
                                .toggleStyle(.checkbox)
                                .font(.system(size: 11))
                            
                            Spacer()
                        }
                        .padding(.vertical, DesignTokens.spacingXS)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingS)
                
                Divider()
                
                // Search Results list
                if filteredResults.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.clipBTextSecondary)
                        Text("No matching entries found.")
                            .foregroundColor(.clipBTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredResults) { entry in
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
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary.opacity(0.8))
                        Text("Select a result")
                            .font(.headline)
                        Text("Select any search match to view its full details.")
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
