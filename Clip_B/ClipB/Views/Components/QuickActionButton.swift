//
//  QuickActionButton.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct QuickActionButton: View {
    let iconName: String
    var label: String? = nil
    let tooltip: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                scale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    scale = 1.0
                }
                action()
            }
        }) {
            HStack(spacing: DesignTokens.spacingXS) {
                Image(systemName: iconName)
                    .font(.system(size: DesignTokens.iconSizeSmall, weight: .medium))
                
                if let label = label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .padding(DesignTokens.spacingS)
            .background(
                isHovered 
                ? (isDestructive ? Color.red.opacity(0.15) : Color.clipBPrimary.opacity(0.15)) 
                : Color.clipBSurfaceElevated.opacity(0.5)
            )
            .foregroundColor(
                isHovered 
                ? (isDestructive ? Color.red : Color.clipBPrimary) 
                : Color.clipBTextPrimary
            )
            .cornerRadius(DesignTokens.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                    .stroke(
                        isHovered 
                        ? (isDestructive ? Color.red.opacity(0.3) : Color.clipBPrimary.opacity(0.3)) 
                        : Color.clipBBorder, 
                        lineWidth: 1
                    )
            )
            .scaleEffect(scale)
            .help(tooltip)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
