//
//  CodeView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct CodeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ClipboardViewModel
    
    var codeEntries: [ClipboardEntry] {
        viewModel.entries.filter { $0.contentType == .code }
    }
    
    var body: some View {
        HSplitView {
            // Master List Pane
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.title2)
                        .foregroundColor(.indigo)
                    Text("Code Snippets")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Text("\(codeEntries.count) snippets")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.clipBTextSecondary)
                        .padding(.horizontal, DesignTokens.spacingS)
                        .padding(.vertical, 2)
                        .background(Color.clipBSurfaceElevated)
                        .cornerRadius(DesignTokens.cornerRadiusSmall)
                }
                .padding(DesignTokens.spacingL)
                
                Divider()
                
                if codeEntries.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary)
                        Text("No Code Snippets")
                            .font(.headline)
                        Text("Any code blocks you copy will automatically appear here.")
                            .font(.subheadline)
                            .foregroundColor(.clipBTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(DesignTokens.spacingXXL)
                } else {
                    List(codeEntries) { entry in
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
                        Image(systemName: "curlybraces")
                            .font(.system(size: 48))
                            .foregroundColor(.clipBTextSecondary.opacity(0.8))
                        Text("Select a snippet")
                            .font(.headline)
                        Text("Select any code entry to view formatted code and options.")
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
