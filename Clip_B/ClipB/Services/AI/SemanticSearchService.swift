//
//  SemanticSearchService.swift
//  ClipB
//
//  Created by ClipB on 2026-07-19.
//

import Foundation
import NaturalLanguage
import Accelerate

/// A fully local semantic search service utilizing Apple's NaturalLanguage framework.
final class SemanticSearchService: Sendable {
    
    static let shared = SemanticSearchService()
    
    private init() {}
    
    /// Generates a 512-dimensional embedding vector for the given text.
    /// Returns nil if the embedding could not be generated (e.g., text too short or unsupported language).
    func generateEmbedding(for text: String) -> [Float]? {
        // Use the built-in English sentence embedding model
        guard let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            return nil
        }
        
        // Optionally, truncate the text if it's too long since NLEmbedding has limits
        let truncatedText = String(text.prefix(2000))
        
        if let vector = sentenceEmbedding.vector(for: truncatedText) {
            // NLEmbedding returns [Double], convert to [Float] to save space and for Accelerate
            return vector.map { Float($0) }
        }
        return nil
    }
    
    /// Encodes a float array into raw Data for SQLite BLOB storage.
    func encode(vector: [Float]) -> Data {
        return vector.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
    }
    
    /// Decodes raw Data from SQLite BLOB back into a float array.
    func decode(data: Data) -> [Float]? {
        guard data.count % MemoryLayout<Float>.size == 0 else { return nil }
        let count = data.count / MemoryLayout<Float>.size
        var vector = [Float](repeating: 0, count: count)
        _ = vector.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return vector
    }
    
    /// Computes the cosine similarity between two vectors using the Accelerate framework.
    func cosineSimilarity(a: [Float], b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }
        
        var dotProduct: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        
        var magA: Float = 0
        vDSP_svesq(a, 1, &magA, vDSP_Length(a.count))
        
        var magB: Float = 0
        vDSP_svesq(b, 1, &magB, vDSP_Length(b.count))
        
        let magnitude = sqrt(magA) * sqrt(magB)
        if magnitude == 0 { return 0 }
        
        return dotProduct / magnitude
    }
}
