//
//  ContentType.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation

/// Represents the type of content stored in a clipboard entry.
///
/// Each case maps to a specific kind of pasteboard payload, and carries
/// presentation metadata (icon, color, human-readable name) used
/// throughout the UI layer.
enum ContentType: String, Codable, Sendable, CaseIterable, Identifiable {
    case text
    case image
    case richText
    case url
    case code
    case file
    case pdf
    case screenshot
    case color
    case email
    case phone

    /// Stable identifier for `Identifiable` conformance.
    var id: String { rawValue }

    /// Human-readable name suitable for display in the UI.
    var displayName: String {
        switch self {
        case .text:       return "Text"
        case .image:      return "Image"
        case .richText:   return "Rich Text"
        case .url:        return "URL"
        case .code:       return "Code"
        case .file:       return "File"
        case .pdf:        return "PDF"
        case .screenshot: return "Screenshot"
        case .color:      return "Color"
        case .email:      return "Email"
        case .phone:      return "Phone"
        }
    }

    /// SF Symbol name representing this content type.
    var iconName: String {
        switch self {
        case .text:       return "doc.text"
        case .image:      return "photo"
        case .richText:   return "doc.richtext"
        case .url:        return "link"
        case .code:       return "chevron.left.forwardslash.chevron.right"
        case .file:       return "doc"
        case .pdf:        return "doc.text.fill"
        case .screenshot: return "camera.viewfinder"
        case .color:      return "paintpalette"
        case .email:      return "envelope"
        case .phone:      return "phone"
        }
    }

    /// Named color used for badge/accent tinting in the UI.
    var accentColor: String {
        switch self {
        case .text:       return "blue"
        case .image:      return "purple"
        case .richText:   return "green"
        case .url:        return "orange"
        case .code:       return "indigo"
        case .file:       return "teal"
        case .pdf:        return "red"
        case .screenshot: return "pink"
        case .color:      return "yellow"
        case .email:      return "cyan"
        case .phone:      return "mint"
        }
    }
}
