//
//  DetailView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    let entry: ClipboardEntry
    
    @EnvironmentObject var viewModel: ClipboardViewModel
    @State private var copiedFeedback = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Info Bar
            HStack(spacing: DesignTokens.spacingM) {
                CategoryBadge(type: entry.contentType)
                
                if let source = entry.sourceApp {
                    Label(source, systemImage: "app")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.clipBTextSecondary)
                }
                
                Spacer()
                
                Text(entry.formattedTimestamp)
                    .font(.system(size: 11))
                    .foregroundColor(.clipBTextSecondary)
            }
            .padding(DesignTokens.spacingL)
            .background(Color.clipBSurfaceElevated.opacity(0.3))
            
            Divider()
            
            // Content Body Area
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                    
                    // Main Preview Payload
                    contentPreviewSection()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    
                    // Smart Tags Section
                    let tagsList = entry.decodedTags
                    if !tagsList.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                            Text("Smart Tags")
                                .sectionHeader()
                            
                            FlowLayout(spacing: DesignTokens.spacingS) {
                                ForEach(tagsList, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, DesignTokens.spacingS)
                                        .padding(.vertical, 3)
                                        .background(Color.clipBPrimary.opacity(0.12))
                                        .foregroundColor(.clipBPrimary)
                                        .cornerRadius(DesignTokens.cornerRadiusSmall)
                                }
                            }
                        }
                    }
                    
                    // AI Summary Card
                    if let summary = entry.aiSummary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("AI Summary")
                                    .sectionHeader()
                            }
                            
                            Text(summary)
                                .font(.system(size: 12))
                                .foregroundColor(.clipBTextPrimary)
                                .lineSpacing(4)
                                .padding(DesignTokens.spacingM)
                                .background(Color.purple.opacity(0.08))
                                .cornerRadius(DesignTokens.cornerRadiusMedium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(DesignTokens.spacingL)
            }
            
            Divider()
            
            // Bottom Action Bar
            HStack(spacing: DesignTokens.spacingM) {
                Button(action: {
                    viewModel.copyToClipboard(entry)
                    withAnimation {
                        copiedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            copiedFeedback = false
                        }
                    }
                }) {
                    HStack(spacing: DesignTokens.spacingXS) {
                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(copiedFeedback ? "Copied!" : "Copy Again")
                    }
                }
                .buttonStyle(PremiumButtonStyle())
                
                Spacer()
                
                QuickActionButton(
                    iconName: entry.isFavorite ? "star.fill" : "star",
                    tooltip: entry.isFavorite ? "Remove from Favorites" : "Add to Favorites"
                ) {
                    viewModel.toggleFavorite(entry)
                }
                
                QuickActionButton(
                    iconName: entry.isPinned ? "pin.fill" : "pin",
                    tooltip: entry.isPinned ? "Unpin" : "Pin"
                ) {
                    viewModel.togglePin(entry)
                }
                
                QuickActionButton(iconName: "square.and.arrow.up", tooltip: "Share") {
                    shareEntry()
                }
                
                QuickActionButton(iconName: "trash", tooltip: "Delete", isDestructive: true) {
                    viewModel.deleteEntry(entry)
                }
            }
            .padding(DesignTokens.spacingL)
            .background(Color.clipBSurfaceElevated.opacity(0.3))
        }
    }
    
    // MARK: - Subviews for Content Preview
    
    @ViewBuilder
    private func contentPreviewSection() -> some View {
        switch entry.contentType {
        case .image, .screenshot:
            if let data = entry.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 350)
                    .cornerRadius(DesignTokens.cornerRadiusMedium)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                imagePlaceholder()
            }
            
        case .color:
            if let colorText = entry.textContent {
                HStack(spacing: DesignTokens.spacingL) {
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .fill(colorFromString(colorText))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .stroke(Color.clipBBorder, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(colorText)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                        Text("Hex / Color string")
                            .font(.system(size: 11))
                            .foregroundColor(.clipBTextSecondary)
                    }
                }
            }
            
        case .code:
            if let code = entry.textContent {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(entry.category ?? "Syntax Highlighted Code")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.clipBTextSecondary)
                        Spacer()
                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(code, forType: .string)
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 12))
                                .foregroundColor(.clipBTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, DesignTokens.spacingS)
                    
                    ScrollView(.horizontal) {
                        Text(code)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.clipBTextPrimary)
                    }
                }
            }
            
        default:
            if let text = entry.textContent {
                Text(text)
                    .font(.body)
                    .foregroundColor(.clipBTextPrimary)
                    .textSelection(.enabled)
                    .lineLimit(nil)
            } else {
                Text("No preview content available.")
                    .foregroundColor(.clipBTextSecondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func imagePlaceholder() -> some View {
        VStack(spacing: DesignTokens.spacingM) {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.clipBTextSecondary)
            Text("Unable to load image data.")
                .foregroundColor(.clipBTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DesignTokens.spacingXL)
    }
    
    private func colorFromString(_ string: String) -> Color {
        // Hex color parsing or default color
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgbValue)
        
        let r, g, b: Double
        if cleaned.count == 6 {
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            return Color(red: r, green: g, blue: b)
        }
        return .clipBPrimary
    }
    
    private func shareEntry() {
        guard let text = entry.textContent else { return }
        let picker = NSSharingServicePicker(items: [text])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
    }
}

// MARK: - FlowLayout for Smart Tags Wrap

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = proposal.width ?? 0
        
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > width {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
        }
        
        height = currentY + maxRowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = bounds.width
        
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            if currentX + size.width > bounds.minX + width {
                currentX = bounds.minX
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
        }
    }
}
