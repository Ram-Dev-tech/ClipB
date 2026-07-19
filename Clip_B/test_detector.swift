import Foundation

// Copying ContentDetector logic for testing
struct ContentDetector {
    static func detectType(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "text" }

        if isEmail(trimmed) { return "email" }
        if isPhone(trimmed) { return "phone" }
        if isURL(trimmed) { return "url" }
        if isColor(trimmed) { return "color" }
        if isJSON(trimmed) { return "code" }
        if isCode(trimmed) { return "code" }
        if isMarkdown(trimmed) { return "richText" }

        return "text"
    }
    
    private static func isURL(_ text: String) -> Bool {
        let lowered = text.lowercased()
        guard lowered.hasPrefix("http://") ||
              lowered.hasPrefix("https://") ||
              lowered.hasPrefix("ftp://") ||
              lowered.hasPrefix("www.") else {
            return false
        }
        if let url = URL(string: text), url.scheme != nil, url.host != nil {
            return true
        }
        if lowered.hasPrefix("www."), let url = URL(string: "https://\(text)"), url.host != nil {
            return true
        }
        return false
    }

    private static func isEmail(_ text: String) -> Bool {
        guard text.contains("@"), text.contains("."), !text.contains(" ") else {
            return false
        }
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return matchesPattern(text, pattern: pattern)
    }

    private static func isPhone(_ text: String) -> Bool {
        let digits = text.filter(\.isNumber)
        guard digits.count >= 7, digits.count <= 15 else { return false }
        let patterns = [
            #"^\+?\d{1,3}[\s\-]?\(?\d{1,4}\)?[\s\-]?\d{1,4}[\s\-]?\d{1,9}$"#,
            #"^\(\d{3}\)\s?\d{3}[\-\s]?\d{4}$"#,
            #"^\d{3}[\-\.\s]\d{3}[\-\.\s]\d{4}$"#,
            #"^\+\d{1,3}\d{6,14}$"#,
        ]
        return patterns.contains { matchesPattern(text, pattern: $0) }
    }

    private static func isCode(_ text: String) -> Bool {
        var score = 0
        if text.contains("{") && text.contains("}") { score += 1 }
        if text.contains("(") && text.contains(")") { score += 1 }
        if text.contains(";") { score += 1 }
        if matchesPattern(text, pattern: #"^\s*(//|/\*|#|--)"#) { score += 1 }
        if matchesPattern(text, pattern: #"(->|=>|::|\|>)"#) { score += 1 }
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
        let lines = text.components(separatedBy: .newlines)
        let indentedLines = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        if lines.count > 2, Double(indentedLines.count) / Double(lines.count) > 0.3 {
            score += 1
        }
        if matchesPattern(text, pattern: #"\w+\s*=\s*[^=]"#) { score += 1 }
        return score >= 3
    }

    private static func isColor(_ text: String) -> Bool {
        let patterns = [
            #"^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"#,
            #"^rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$"#,
            #"^hsla?\(\s*\d{1,3}\s*,\s*\d{1,3}%?\s*,\s*\d{1,3}%?\s*(,\s*[\d.]+\s*)?\)$"#,
        ]
        return patterns.contains { matchesPattern(text, pattern: $0) }
    }

    private static func isJSON(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func isMarkdown(_ text: String) -> Bool {
        var indicators = 0
        if matchesPattern(text, pattern: #"(?m)^#{1,6}\s+"#) { indicators += 1 }
        if text.contains("**") || text.contains("__") { indicators += 1 }
        if matchesPattern(text, pattern: #"\[.+?\]\(.+?\)"#) { indicators += 1 }
        if text.contains("```") { indicators += 1 }
        if matchesPattern(text, pattern: #"`[^`]+`"#) { indicators += 1 }
        if matchesPattern(text, pattern: #"(?m)^[\-\*]\s+"#) { indicators += 1 }
        if matchesPattern(text, pattern: #"!\[.*?\]\(.+?\)"#) { indicators += 1 }
        return indicators >= 2
    }

    private static func matchesPattern(_ text: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}

let tests = [
    "let url = \"https://example.com\";\nprint(url)",
    "@StateObject var foo = Bar()",
    "http://github.com/apple/swift",
    "func test() {}",
    "someone@example.com",
    "// test\nlet x = 1;"
]

for t in tests {
    let result = ContentDetector.detectType(from: t)
    print("\(t) -> \(result)")
}
