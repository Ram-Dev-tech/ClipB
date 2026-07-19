//
//  DesignSystem.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    static var clipBPrimary: Color {
        Color(nsColor: .controlAccentColor)
    }
    
    static var clipBSecondary: Color {
        Color.purple
    }
    
    static var clipBSurface: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    static var clipBSurfaceElevated: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    static var clipBBorder: Color {
        Color(nsColor: .separatorColor)
    }
    
    static var clipBTextPrimary: Color {
        Color(nsColor: .labelColor)
    }
    
    static var clipBTextSecondary: Color {
        Color(nsColor: .secondaryLabelColor)
    }
    
    static var clipBGradientStart: Color {
        Color.blue
    }
    
    static var clipBGradientEnd: Color {
        Color.purple
    }
}

// MARK: - Design Tokens

struct DesignTokens {
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusMedium: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 14
    static let cornerRadiusXL: CGFloat = 20
    
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    
    static let iconSizeSmall: CGFloat = 14
    static let iconSizeMedium: CGFloat = 18
    static let iconSizeLarge: CGFloat = 24
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.spacingL)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignTokens.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                    .stroke(Color.clipBBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.clipBPrimary.opacity(0.15) : Color.clear)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, DesignTokens.spacingS)
            .padding(.horizontal, DesignTokens.spacingL)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.clipBGradientStart, Color.clipBGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignTokens.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .shadow(color: Color.clipBPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

struct SubtleButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, DesignTokens.spacingS)
            .padding(.horizontal, DesignTokens.spacingM)
            .background(
                isHovered 
                ? Color.clipBPrimary.opacity(0.1) 
                : (configuration.isPressed ? Color.clipBPrimary.opacity(0.2) : Color.clear)
            )
            .cornerRadius(DesignTokens.cornerRadiusSmall)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func hoverHighlight() -> some View {
        self.modifier(HoverHighlightModifier())
    }
    
    func sectionHeader() -> some View {
        self
            .font(.system(size: 11, weight: .bold, design: .default))
            .foregroundColor(.clipBTextSecondary)
            .textCase(.uppercase)
    }
}
