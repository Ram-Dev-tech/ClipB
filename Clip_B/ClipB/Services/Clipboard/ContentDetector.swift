//
//  ContentDetector.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation

/// Detects content type and metadata from clipboard text.
///
/// `ContentDetector` examines raw text to determine the most specific
/// `ContentType`, identify programming languages, and generate a set
/// of basic tags for organisation and search.
///
/// Detection follows a priority order — more specific types (email,
/// phone, URL, color, code) are checked before falling back to
/// generic text.
struct ContentDetector: Sendable {

    // MARK: - Public API

    /// Detect the most specific content type for the given text.
    ///
    /// Priority (highest → lowest):
    /// email → phone → URL → color → code → richText (markdown) → text
    ///
    /// - Parameter text: The raw clipboard string.
    /// - Returns: The detected `ContentType`.
    static func detectType(from text: String) -> ContentType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .text }

        if isEmail(trimmed) { return .email }
        if isPhone(trimmed) { return .phone }
        if isURL(trimmed) { return .url }
        if isColor(trimmed) { return .color }
        if isJSON(trimmed) { return .code }
        if isCode(trimmed) { return .code }
        if isMarkdown(trimmed) { return .richText }

        return .text
    }

    /// Attempt to identify the programming language of a code snippet.
    ///
    /// Returns `nil` when the language cannot be determined with
    /// reasonable confidence.
    ///
    /// - Parameter code: The source code string.
    /// - Returns: A human-readable language name, or `nil`.
    static func detectLanguage(from code: String) -> String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

        // Order matters — check more specific indicators first.

        // HTML / XML
        if trimmed.hasPrefix("<!DOCTYPE") || trimmed.hasPrefix("<html") || trimmed.hasPrefix("<?xml") {
            return "HTML"
        }

        // Shell / Bash
        if trimmed.hasPrefix("#!/bin/bash") || trimmed.hasPrefix("#!/bin/sh") || trimmed.hasPrefix("#!/usr/bin/env bash") {
            return "Bash"
        }

        // Python shebang
        if trimmed.hasPrefix("#!/usr/bin/env python") || trimmed.hasPrefix("#!/usr/bin/python") {
            return "Python"
        }

        // CSS
        if matchesPattern(trimmed, pattern: #"@media\s|@keyframes\s|@import\s"#) &&
           matchesPattern(trimmed, pattern: #"\{[^}]*\}"#) {
            return "CSS"
        }

        // SQL
        let sqlKeywords = ["SELECT", "INSERT INTO", "UPDATE", "DELETE FROM", "CREATE TABLE", "ALTER TABLE", "DROP TABLE"]
        let upper = trimmed.uppercased()
        for keyword in sqlKeywords {
            if upper.hasPrefix(keyword) || upper.contains("\n\(keyword)") {
                return "SQL"
            }
        }

        // Swift
        let swiftIndicators = [
            #"func\s+\w+\s*\("#,
            #"let\s+\w+\s*[:=]"#,
            #"var\s+\w+\s*[:=]"#,
            #"import\s+(Foundation|UIKit|SwiftUI|AppKit|Combine)"#,
            #"@(State|Binding|Published|ObservableObject|MainActor|Sendable)\b"#,
            #"struct\s+\w+\s*:\s*(View|Codable|Identifiable)"#,
        ]
        if matchesAnyPattern(trimmed, patterns: swiftIndicators) {
            return "Swift"
        }

        // Kotlin (before Java — Kotlin shares some keywords)
        let kotlinIndicators = [
            #"fun\s+\w+\s*\("#,
            #"val\s+\w+\s*[:=]"#,
            #"data\s+class\s+"#,
            #"suspend\s+fun\s+"#,
        ]
        if matchesAnyPattern(trimmed, patterns: kotlinIndicators) {
            return "Kotlin"
        }

        // Java
        let javaIndicators = [
            #"public\s+(static\s+)?class\s+\w+"#,
            #"public\s+static\s+void\s+main"#,
            #"import\s+java\."#,
            #"System\.out\.print"#,
        ]
        if matchesAnyPattern(trimmed, patterns: javaIndicators) {
            return "Java"
        }

        // C++ / C
        if trimmed.contains("#include") {
            if trimmed.contains("<iostream>") || trimmed.contains("std::") || trimmed.contains("cout") {
                return "C++"
            }
            return "C"
        }

        // Rust
        let rustIndicators = [
            #"fn\s+\w+\s*\("#,
            #"let\s+mut\s+"#,
            #"impl\s+\w+"#,
            #"use\s+std::"#,
        ]
        if matchesAnyPattern(trimmed, patterns: rustIndicators) {
            return "Rust"
        }

        // Go
        let goIndicators = [
            #"func\s+\w+\s*\("#,
            #"package\s+\w+"#,
            #"import\s+\("#,
            #"fmt\.Print"#,
        ]
        // Go uses `func` like Swift but `package` is unique
        if matchesPattern(trimmed, pattern: #"package\s+\w+"#) &&
           matchesAnyPattern(trimmed, patterns: goIndicators) {
            return "Go"
        }

        // TypeScript (before JavaScript)
        let tsIndicators = [
            #":\s*(string|number|boolean|any|void)\b"#,
            #"interface\s+\w+\s*\{"#,
            #"type\s+\w+\s*="#,
            #"<\w+>"#,
        ]
        if matchesAnyPattern(trimmed, patterns: tsIndicators) &&
           matchesPattern(trimmed, pattern: #"(const|let|var|function|import|export)\b"#) {
            return "TypeScript"
        }

        // JavaScript
        let jsIndicators = [
            #"(const|let|var)\s+\w+\s*="#,
            #"function\s+\w+\s*\("#,
            #"=>\s*\{"#,
            #"console\.log"#,
            #"require\s*\("#,
            #"module\.exports"#,
            #"import\s+.*\s+from\s+"#,
        ]
        if matchesAnyPattern(trimmed, patterns: jsIndicators) {
            return "JavaScript"
        }

        // Python (general — checked after shebang)
        let pythonIndicators = [
            #"def\s+\w+\s*\("#,
            #"import\s+\w+"#,
            #"from\s+\w+\s+import"#,
            #"class\s+\w+\s*(\(|:)"#,
            #"print\s*\("#,
            #"if\s+__name__\s*==\s*['\"]__main__['\"]"#,
        ]
        if matchesAnyPattern(trimmed, patterns: pythonIndicators) {
            return "Python"
        }

        // Ruby
        let rubyIndicators = [
            #"def\s+\w+"#,
            #"puts\s+"#,
            #"require\s+['\"]"#,
            #"class\s+\w+\s*<\s*\w+"#,
            #"end\s*$"#,
        ]
        if matchesAnyPattern(trimmed, patterns: rubyIndicators) &&
           !matchesPattern(trimmed, pattern: #"print\s*\("#) { // disambiguate from Python
            return "Ruby"
        }

        // JSON (already handled as `isJSON` → .code, but language hint)
        if isJSON(trimmed) {
            return "JSON"
        }

        return nil
    }

    /// Generate basic organisational tags from content.
    ///
    /// Tags are short strings useful for filtering and search.
    ///
    /// - Parameters:
    ///   - text: The raw content string.
    ///   - type: The detected `ContentType`.
    /// - Returns: An array of tag strings.
    static func generateBasicTags(from text: String, type: ContentType) -> [String] {
        var tags: [String] = []
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Always include the content type display name.
        tags.append(type.displayName)

        switch type {
        case .url:
            tags.append("URL")
            if let url = URL(string: trimmed), let host = url.host {
                tags.append(host)
                // Well-known domains get extra tags.
                if host.contains("github.com") { tags.append("GitHub") }
                if host.contains("stackoverflow.com") { tags.append("StackOverflow") }
                if host.contains("google.com") { tags.append("Google") }
                if host.contains("youtube.com") { tags.append("YouTube") }
                if host.contains("twitter.com") || host.contains("x.com") { tags.append("Twitter") }
                if host.contains("linkedin.com") { tags.append("LinkedIn") }
                if host.contains("reddit.com") { tags.append("Reddit") }
                if host.contains("medium.com") { tags.append("Medium") }
                if host.contains("notion.so") || host.contains("notion.site") { tags.append("Notion") }
                if host.contains("figma.com") { tags.append("Figma") }
            }

        case .email:
            tags.append("Email")
            if let atIndex = trimmed.firstIndex(of: "@") {
                let domain = String(trimmed[trimmed.index(after: atIndex)...])
                tags.append(domain)
            }

        case .phone:
            tags.append("Phone")
            if trimmed.hasPrefix("+1") || trimmed.hasPrefix("1-") { tags.append("US") }
            if trimmed.hasPrefix("+44") { tags.append("UK") }
            if trimmed.hasPrefix("+91") { tags.append("India") }

        case .code:
            tags.append("Code")
            if let language = detectLanguage(from: trimmed) {
                tags.append(language)
            }
            if isJSON(trimmed) { tags.append("JSON") }

        case .color:
            tags.append("Color")
            if trimmed.hasPrefix("#") { tags.append("Hex") }
            if trimmed.lowercased().hasPrefix("rgb") { tags.append("RGB") }
            if trimmed.lowercased().hasPrefix("hsl") { tags.append("HSL") }

        case .richText:
            tags.append("Rich Text")
            if isMarkdown(trimmed) { tags.append("Markdown") }

        case .text:
            // Length-based tags.
            if trimmed.count > 500 { tags.append("Long Text") }
            if trimmed.count <= 50 { tags.append("Short") }
            // Detect lists.
            let lines = trimmed.components(separatedBy: .newlines)
            let bulletCount = lines.filter { $0.hasPrefix("- ") || $0.hasPrefix("• ") || $0.hasPrefix("* ") }.count
            if bulletCount >= 3 { tags.append("List") }
            let numberedCount = lines.filter { matchesPattern($0, pattern: #"^\d+[\.\)]\s"#) }.count
            if numberedCount >= 3 { tags.append("Numbered List") }

        case .image:
            tags.append("Image")

        case .screenshot:
            tags.append("Screenshot")

        case .file:
            tags.append("File")

        case .pdf:
            tags.append("PDF")
        }

        // Deduplicate while preserving order.
        var seen = Set<String>()
        return tags.filter { seen.insert($0).inserted }
    }

    // MARK: - Private Detection Helpers

    /// Returns `true` if the trimmed string is a valid URL.
    private static func isURL(_ text: String) -> Bool {
        // Must look like a URL (starts with scheme or www.)
        let lowered = text.lowercased()
        guard lowered.hasPrefix("http://") ||
              lowered.hasPrefix("https://") ||
              lowered.hasPrefix("ftp://") ||
              lowered.hasPrefix("www.") else {
            return false
        }
        // Validate with Foundation.
        if let url = URL(string: text), url.scheme != nil, url.host != nil {
            return true
        }
        // Handle www. without scheme.
        if lowered.hasPrefix("www."), let url = URL(string: "https://\(text)"), url.host != nil {
            return true
        }
        return false
    }

    /// Returns `true` if the trimmed string looks like an email address.
    private static func isEmail(_ text: String) -> Bool {
        // Quick structural check before regex.
        guard text.contains("@"), text.contains("."), !text.contains(" ") else {
            return false
        }
        // RFC-5322 simplified pattern.
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return matchesPattern(text, pattern: pattern)
    }

    /// Returns `true` if the trimmed string looks like a phone number.
    private static func isPhone(_ text: String) -> Bool {
        // Strip common formatting characters.
        let digits = text.filter(\.isNumber)
        guard digits.count >= 7, digits.count <= 15 else { return false }

        // Match common phone patterns.
        let patterns = [
            #"^\+?\d{1,3}[\s\-]?\(?\d{1,4}\)?[\s\-]?\d{1,4}[\s\-]?\d{1,9}$"#,  // International
            #"^\(\d{3}\)\s?\d{3}[\-\s]?\d{4}$"#,                                   // US (xxx) xxx-xxxx
            #"^\d{3}[\-\.\s]\d{3}[\-\.\s]\d{4}$"#,                                 // US xxx-xxx-xxxx
            #"^\+\d{1,3}\d{6,14}$"#,                                                // Compact international
        ]
        return patterns.contains { matchesPattern(text, pattern: $0) }
    }

    /// Returns `true` if the text appears to be source code.
    private static func isCode(_ text: String) -> Bool {
        // Multi-line heuristic: look for a threshold of code indicators.
        var score = 0

        // Structural indicators
        if text.contains("{") && text.contains("}") { score += 1 }
        if text.contains("(") && text.contains(")") { score += 1 }
        if text.contains(";") { score += 1 }
        if matchesPattern(text, pattern: #"^\s*(//|/\*|#|--)"#) { score += 1 } // comment
        if matchesPattern(text, pattern: #"(->|=>|::|\|>)"#) { score += 1 }     // operators

        // Keyword indicators (any language)
        let codeKeywords = [
            "function", "func ", "def ", "class ", "struct ", "enum ",
            "import ", "return ", "const ", "let ", "var ", "if ", "else ",
            "for ", "while ", "switch ", "case ", "try ", "catch ",
            "public ", "private ", "static ", "#include", "package ",
            "interface ", "protocol ", "extension ", "impl ",
        ]
        for keyword in codeKeywords {
            if text.contains(keyword) {
                score += 1
                break
            }
        }

        // Indentation pattern (lines starting with spaces/tabs)
        let lines = text.components(separatedBy: .newlines)
        let indentedLines = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        if lines.count > 2, Double(indentedLines.count) / Double(lines.count) > 0.3 {
            score += 1
        }

        // Assignment operators
        if matchesPattern(text, pattern: #"\w+\s*=\s*[^=]"#) { score += 1 }

        return score >= 3
    }

    /// Returns `true` if the text looks like a color value.
    private static func isColor(_ text: String) -> Bool {
        let patterns = [
            #"^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"#,  // Hex
            #"^rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$"#, // rgb/rgba
            #"^hsla?\(\s*\d{1,3}\s*,\s*\d{1,3}%?\s*,\s*\d{1,3}%?\s*(,\s*[\d.]+\s*)?\)$"#, // hsl/hsla
        ]
        return patterns.contains { matchesPattern(text, pattern: $0) }
    }

    /// Returns `true` if the text is valid JSON.
    private static func isJSON(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        // Must start with { or [ to be a JSON object/array.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    /// Returns `true` if the text contains Markdown formatting.
    private static func isMarkdown(_ text: String) -> Bool {
        var indicators = 0

        // Headings
        if matchesPattern(text, pattern: #"(?m)^#{1,6}\s+"#) { indicators += 1 }
        // Bold / italic
        if text.contains("**") || text.contains("__") { indicators += 1 }
        // Links
        if matchesPattern(text, pattern: #"\[.+?\]\(.+?\)"#) { indicators += 1 }
        // Code blocks
        if text.contains("```") { indicators += 1 }
        // Inline code
        if matchesPattern(text, pattern: #"`[^`]+`"#) { indicators += 1 }
        // Unordered list
        if matchesPattern(text, pattern: #"(?m)^[\-\*]\s+"#) { indicators += 1 }
        // Images
        if matchesPattern(text, pattern: #"!\[.*?\]\(.+?\)"#) { indicators += 1 }

        return indicators >= 2
    }

    // MARK: - Regex Utilities

    /// Returns `true` if the text matches the given regex pattern.
    private static func matchesPattern(_ text: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    /// Returns `true` if the text matches any of the given regex patterns.
    private static func matchesAnyPattern(_ text: String, patterns: [String]) -> Bool {
        patterns.contains { matchesPattern(text, pattern: $0) }
    }
}
