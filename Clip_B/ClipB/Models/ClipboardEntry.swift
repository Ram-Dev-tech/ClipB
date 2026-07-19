//
//  ClipboardEntry.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation
import GRDB

/// A single clipboard history entry with metadata, content, and AI annotations.
///
/// Each time the user copies something, a new `ClipboardEntry` is persisted
/// to the local GRDB database. The struct carries the raw content (text or
/// image data), a short preview, detected content type, optional AI-generated
/// summary, and organisational flags (favorite, pinned, collection).
struct ClipboardEntry: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {

    // MARK: - Stored Properties

    /// Unique identifier (UUID string).
    var id: String

    /// When the entry was captured.
    var timestamp: Date

    /// Detected or overridden content type.
    var contentType: ContentType

    /// Plain-text representation of the content, if applicable.
    var textContent: String?

    /// Raw image data (PNG/TIFF), if the entry is an image or screenshot.
    var imageData: Data?

    /// Truncated preview string (first 200 characters or an image description).
    var preview: String

    /// AI-assigned category label (e.g. "work", "research").
    var category: String?

    /// JSON-encoded `[String]` of user/AI tags.
    var tags: String?

    /// Short AI-generated summary of the content.
    var aiSummary: String?

    /// Whether the user has marked this entry as a favorite.
    var isFavorite: Bool

    /// Whether the entry is pinned to the top of the list.
    var isPinned: Bool

    /// Whether the content is stored in encrypted form.
    var isEncrypted: Bool

    /// Optional foreign key to a `Collection`.
    var collectionId: String?

    /// Bundle name / path of the application the content was copied from.
    var sourceApp: String?
    
    /// Optional local semantic embedding (512-dimensional vector stored as Data).
    var embedding: Data?

    // MARK: - Table Mapping

    /// GRDB table name.
    static let databaseTableName = "clipboardEntries"

    // MARK: - Initialiser

    /// Creates a new `ClipboardEntry` with sensible defaults.
    ///
    /// - Parameters:
    ///   - id: UUID string. Defaults to a new UUID.
    ///   - timestamp: Capture time. Defaults to now.
    ///   - contentType: Detected content type.
    ///   - textContent: Optional plain-text payload.
    ///   - imageData: Optional image payload.
    ///   - preview: Truncated preview string.
    ///   - category: Optional category label.
    ///   - tags: Optional JSON-encoded tags array.
    ///   - aiSummary: Optional AI summary.
    ///   - isFavorite: Defaults to `false`.
    ///   - isPinned: Defaults to `false`.
    ///   - isEncrypted: Defaults to `false`.
    ///   - collectionId: Optional collection foreign key.
    ///   - sourceApp: Optional source application identifier.
    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        contentType: ContentType,
        textContent: String? = nil,
        imageData: Data? = nil,
        preview: String,
        category: String? = nil,
        tags: String? = nil,
        aiSummary: String? = nil,
        isFavorite: Bool = false,
        isPinned: Bool = false,
        isEncrypted: Bool = false,
        collectionId: String? = nil,
        sourceApp: String? = nil,
        embedding: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.preview = preview
        self.category = category
        self.tags = tags
        self.aiSummary = aiSummary
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.isEncrypted = isEncrypted
        self.collectionId = collectionId
        self.sourceApp = sourceApp
        self.embedding = embedding
    }

    // MARK: - Computed Properties

    /// Decoded tags array from the JSON-encoded `tags` column.
    ///
    /// Returns an empty array if `tags` is nil or the JSON is malformed.
    var decodedTags: [String] {
        guard let tags, let data = tags.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            return []
        }
    }

    /// The timeline section this entry belongs to, derived from `timestamp`.
    var timelineSection: TimelineSection {
        TimelineSection.section(for: timestamp)
    }

    /// A human-friendly relative time string (e.g. "Just now", "5 min ago").
    var formattedTimestamp: String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)

        // Future-dated or essentially "now"
        if interval < 30 {
            return "Just now"
        }

        let minutes = Int(interval / 60)
        if minutes < 1 {
            return "Just now"
        }
        if minutes == 1 {
            return "1 min ago"
        }
        if minutes < 60 {
            return "\(minutes) min ago"
        }

        let hours = minutes / 60
        if hours == 1 {
            return "1 hour ago"
        }
        if hours < 24 {
            return "\(hours) hours ago"
        }

        let calendar = Calendar.current
        if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        }

        let days = hours / 24
        if days < 7 {
            return "\(days) days ago"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: timestamp)
    }
}
