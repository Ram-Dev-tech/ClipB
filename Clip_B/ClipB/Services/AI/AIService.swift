//
//  AIService.swift
//  ClipB
//
//  Created by ClipB on 2026-07-19.
//

import Foundation

/// A service to interact with LLM providers (OpenAI, OpenRouter, Ollama) 
/// using the standard OpenAI chat completions API format.
final class AIService: Sendable {
    
    static let shared = AIService()
    
    private init() {}
    
    /// Struct representing the JSON schema we expect the LLM to return.
    private struct AIResponseFormat: Codable {
        var summary: String?
        var tags: [String]?
        var title: String? // For code snippets
        var extractedText: String? // For OCR
    }
    
    func process(entry: ClipboardEntry) async -> ClipboardEntry? {
        let defaults = UserDefaults.standard
        let aiEnabled = defaults.bool(forKey: "aiEnabled")
        guard aiEnabled else { return nil }
        
        let autoSummarize = defaults.bool(forKey: "aiAutoSummarize")
        let autoTag = defaults.bool(forKey: "aiAutoTag")
        let autoTitle = defaults.bool(forKey: "aiAutoTitle")
        let autoOCR = defaults.bool(forKey: "aiAutoOCR")
        
        // Determine what needs to be done based on flags and content type
        var needsSummary = autoSummarize && (entry.contentType == .richText || entry.contentType == .text || entry.contentType == .url)
        let needsTags = autoTag
        let needsTitle = autoTitle && entry.contentType == .code
        let needsOCR = autoOCR && (entry.contentType == .image || entry.contentType == .screenshot)
        
        if !needsSummary && !needsTags && !needsTitle && !needsOCR {
            return nil
        }
        
        let textContent = entry.textContent ?? ""
        // Hard cap on context length to prevent massive token usage and timeouts (20,000 chars ~ 5,000 tokens)
        if textContent.count > 20000 {
            // Disable summary for very long texts to save money/time, but maybe keep tags which require less context
            needsSummary = false
        }
        
        // For OCR, we would need to send image data to a Vision model. 
        // For simplicity in this implementation, we will skip actual image OCR via LLM unless it's a vision model.
        // We will focus on text-based enrichment.
        if entry.imageData != nil {
            return nil // Image processing requires vision models, skipping for now to ensure stability
        }
        
        guard !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var promptInstructions = [String]()
        if needsSummary { promptInstructions.append("- \"summary\": A 1-2 sentence concise summary of the content.") }
        if needsTags { promptInstructions.append("- \"tags\": An array of 1 to 4 relevant tags (lowercase).") }
        if needsTitle { promptInstructions.append("- \"title\": A short, descriptive title for this code snippet.") }
        
        let systemPrompt = """
        You are an intelligent clipboard assistant. Analyze the provided clipboard content and extract metadata.
        Return ONLY valid JSON matching this schema:
        {
            \(promptInstructions.joined(separator: "\n    "))
        }
        Do not include markdown code blocks or any other text.
        """
        
        let provider = defaults.string(forKey: "aiProvider") ?? "openrouter"
        let apiKey = defaults.string(forKey: "aiApiKey") ?? ""
        var endpoint = defaults.string(forKey: "aiEndpoint") ?? ""
        let model = defaults.string(forKey: "aiModelName") ?? "openrouter/auto"
        let temperature = defaults.double(forKey: "aiTemperature")
        
        if endpoint.isEmpty {
            switch provider {
            case "openai": endpoint = "https://api.openai.com/v1/chat/completions"
            case "ollama": endpoint = "http://localhost:11434/v1/chat/completions"
            default: endpoint = "https://openrouter.ai/api/v1/chat/completions" // Default to openrouter
            }
        }
        
        guard let url = URL(string: endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if provider != "ollama" && !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        if provider == "openrouter" {
            request.addValue("ClipB", forHTTPHeaderField: "HTTP-Referer")
            request.addValue("ClipB", forHTTPHeaderField: "X-Title")
        }
        
        let requestBody: [String: Any] = [
            "model": model,
            "temperature": temperature == 0.0 ? 0.7 : temperature,
            "response_format": ["type": "json_object"], // Enforce JSON
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": textContent.prefix(15000)] // Send up to 15k chars
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[AIService] Error response: \(String(data: data, encoding: .utf8) ?? "Unknown")")
                return nil
            }
            
            // Parse OpenAI format response
            struct OpenAIResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = result.choices.first?.message.content else { return nil }
            
            // The content should be JSON
            guard let jsonData = content.data(using: .utf8) else { return nil }
            let parsedAI = try JSONDecoder().decode(AIResponseFormat.self, from: jsonData)
            
            var updatedEntry = entry
            
            if let summary = parsedAI.summary, needsSummary {
                updatedEntry.aiSummary = summary
            }
            
            if let tags = parsedAI.tags, needsTags, !tags.isEmpty {
                // Merge with existing basic tags
                var existingTags = entry.decodedTags
                for t in tags {
                    if !existingTags.contains(t) {
                        existingTags.append(t)
                    }
                }
                if let encoded = try? JSONEncoder().encode(existingTags) {
                    updatedEntry.tags = String(data: encoded, encoding: .utf8)
                }
            }
            
            if let title = parsedAI.title, needsTitle {
                updatedEntry.preview = title
            }
            
            return updatedEntry
            
        } catch {
            print("[AIService] Error calling LLM: \(error)")
            return nil
        }
    }
}
