//
//  ClipboardListView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    var body: some View {
        HSplitView {
            // Master List Pane
            VStack(spacing: 0) {
                // Search Bar + Filter Chips
                SearchBar()
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.spacingL)
                    .padding(.bottom, DesignTokens.spacingS)
                
                Divider()
                
                // History List
                if viewModel.entries.isEmpty {
                    emptyStateView()
                } else {
                    List {
                        ForEach(viewModel.groupedEntries, id: \.0) { section, entries in
                            Section(header: Text(section.displayName).sectionHeader().padding(.vertical, DesignTokens.spacingXS)) {
                                ForEach(entries) { entry in
                                    ClipboardEntryRow(entry: entry)
                                        .onAppear {
                                            // Trigger pagination when reaching the end
                                            if entry.id == viewModel.entries.last?.id {
                                                viewModel.loadMore()
                                            }
                                        }
                                }
                            }
                        }
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
                    noSelectionView()
                }
            }
            .frame(minWidth: 350, maxWidth: .infinity)
        }
    }
    
    // MARK: - Subviews
    
    private func emptyStateView() -> some View {
        VStack(spacing: DesignTokens.spacingM) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(.clipBTextSecondary)
            Text("No Clipboard Items Found")
                .font(.headline)
            Text("Copy text, images, or files to populate history.")
                .font(.subheadline)
                .foregroundColor(.clipBTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.spacingXXL)
    }
    
    private func noSelectionView() -> some View {
        VStack(spacing: DesignTokens.spacingM) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.clipBTextSecondary.opacity(0.8))
            Text("Select an item")
                .font(.headline)
            Text("Select a clipboard entry to preview its details.")
                .font(.subheadline)
                .foregroundColor(.clipBTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clipBSurface)
    }
}
