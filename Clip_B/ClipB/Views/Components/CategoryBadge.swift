//
//  CategoryBadge.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

struct CategoryBadge: View {
    let type: ContentType
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingXS) {
            Image(systemName: type.iconName)
                .font(.system(size: 9, weight: .bold))
            Text(type.displayName)
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.vertical, 2)
        .background(colorForType(type).opacity(0.15))
        .foregroundColor(colorForType(type))
        .cornerRadius(DesignTokens.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                .stroke(colorForType(type).opacity(0.3), lineWidth: 1)
        )
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
        default: return .blue
        }
    }
}
