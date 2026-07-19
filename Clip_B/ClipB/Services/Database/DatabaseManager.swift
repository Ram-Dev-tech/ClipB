//
//  DatabaseManager.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation
import GRDB

/// Central database manager wrapping a GRDB `DatabasePool`.
///
/// Provides the shared database connection, runs schema migrations on
/// first launch, and exposes type-safe CRUD operations for
/// `ClipboardEntry` and `Collection` records.
///
/// Usage:
/// ```swift
/// try DatabaseManager.shared.initialize()
/// let entries = try DatabaseManager.shared.fetchEntries(limit: 50)
/// ```
@MainActor
final class DatabaseManager: Sendable {

    // MARK: - Singleton

    /// Shared instance. Call `initialize()` once at app launch.
    static let shared = DatabaseManager()

    // MARK: - Storage

    /// The underlying GRDB connection pool.
    ///
    /// Marked `nonisolated(unsafe)` because it is written exactly once
    /// inside `initialize()` on the main actor and thereafter only read.
    nonisolated(unsafe) private var dbPool: DatabasePool?

    /// A `DatabaseReader` for observation and read-only queries.
    var reader: DatabaseReader {
        guard let pool = dbPool else {
            fatalError("DatabaseManager.initialize() must be called before accessing the database.")
        }
        return pool
    }

    /// A `DatabaseWriter` for mutations.
    var writer: DatabaseWriter {
        guard let pool = dbPool else {
            fatalError("DatabaseManager.initialize() must be called before accessing the database.")
        }
        return pool
    }

    // MARK: - Lifecycle

    private init() {}

    /// Opens (or creates) the database at
    /// `~/Library/Application Support/ClipB/clipb.db`,
    /// enables WAL mode and foreign keys, and runs pending migrations.
    func initialize() throws {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("ClipB", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let databaseURL = directoryURL.appendingPathComponent("clipb.db")

        var configuration = Configuration()
        configuration.prepareDatabase { db in
            // Enable WAL for concurrent readers.
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            // Enforce referential integrity.
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        let pool = try DatabasePool(path: databaseURL.path, configuration: configuration)

        // Run migrations.
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        AppMigrations.registerMigrations(&migrator)
        try migrator.migrate(pool)

        self.dbPool = pool
    }

    // MARK: - ClipboardEntry CRUD

    /// Insert a new clipboard entry.
    ///
    /// - Parameter entry: The entry to persist.
    func insertEntry(_ entry: ClipboardEntry) throws {
        try writer.write { db in
            try entry.insert(db)
        }
    }

    /// Delete a clipboard entry by its identifier.
    ///
    /// - Parameter id: UUID string of the entry to remove.
    func deleteEntry(id: String) throws {
        try writer.write { db in
            _ = try ClipboardEntry.deleteOne(db, id: id)
        }
    }

    /// Update an existing clipboard entry (full row replacement).
    ///
    /// - Parameter entry: The entry with updated fields.
    func updateEntry(_ entry: ClipboardEntry) throws {
        try writer.write { db in
            try entry.update(db)
        }
    }

    /// Fetch clipboard entries with optional filtering and pagination.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of rows to return.
    ///   - offset: Number of rows to skip (for pagination).
    ///   - contentType: Optional filter by content type.
    ///   - searchQuery: Optional full-text search query.
    ///   - startDate: Optional minimum timestamp.
    /// - Returns: An array of matching `ClipboardEntry` records ordered
    ///   by pinned status (descending) then timestamp (descending).
    func fetchEntries(
        limit: Int = 50,
        offset: Int = 0,
        contentType: ContentType? = nil,
        searchQuery: String? = nil,
        startDate: Date? = nil
    ) throws -> [ClipboardEntry] {
        try reader.read { db in
            // If a search query is provided, use FTS5.
            if let query = searchQuery, !query.isEmpty {
                let ftsPattern = FTS5Pattern(matchingAnyTokenIn: query)
                if let pattern = ftsPattern {
                    var sql = """
                        SELECT clipboardEntries.*
                        FROM clipboardEntries
                        JOIN clipboardEntries_fts ON clipboardEntries_fts.rowid = clipboardEntries.rowid
                        WHERE clipboardEntries_fts MATCH ?
                        """
                    var arguments: [DatabaseValueConvertible] = [pattern]

                    if let contentType {
                        sql += " AND clipboardEntries.contentType = ?"
                        arguments.append(contentType.rawValue)
                    }

                    if let startDate {
                        sql += " AND clipboardEntries.timestamp >= ?"
                        arguments.append(startDate)
                    }

                    sql += " ORDER BY clipboardEntries.isPinned DESC, clipboardEntries.timestamp DESC"
                    sql += " LIMIT ? OFFSET ?"
                    arguments.append(limit)
                    arguments.append(offset)

                    return try ClipboardEntry.fetchAll(
                        db,
                        sql: sql,
                        arguments: StatementArguments(arguments)
                    )
                }
            }

            // Standard query (no search or empty query).
            var request = ClipboardEntry
                .order(Column("isPinned").desc, Column("timestamp").desc)

            if let contentType {
                request = request.filter(Column("contentType") == contentType.rawValue)
            }

            if let startDate {
                request = request.filter(Column("timestamp") >= startDate)
            }

            // LIKE fallback for non-FTS queries when searchQuery is provided
            // but FTS pattern creation failed.
            if let query = searchQuery, !query.isEmpty {
                let likePattern = "%\(query)%"
                request = request.filter(
                    Column("textContent").like(likePattern) ||
                    Column("preview").like(likePattern) ||
                    Column("tags").like(likePattern) ||
                    Column("aiSummary").like(likePattern)
                )
            }

            return try request
                .limit(limit, offset: offset)
                .fetchAll(db)
        }
    }
    
    /// Perform a semantic search by computing cosine similarity in-memory against all entries with embeddings.
    /// - Parameters:
    ///   - query: The text to search for.
    ///   - limit: Maximum number of results to return.
    /// - Returns: An array of `ClipboardEntry` ordered by semantic relevance (highest similarity first).
    func semanticSearch(query: String, limit: Int = 10) throws -> [ClipboardEntry] {
        guard let queryEmbedding = SemanticSearchService.shared.generateEmbedding(for: query) else {
            return [] // Could not generate embedding for query
        }
        
        let allEntries = try reader.read { db in
            try ClipboardEntry
                .filter(Column("embedding") != nil)
                .fetchAll(db)
        }
        
        var scoredEntries: [(entry: ClipboardEntry, score: Float)] = []
        
        for entry in allEntries {
            if let embeddingData = entry.embedding,
               let embedding = SemanticSearchService.shared.decode(data: embeddingData) {
                let score = SemanticSearchService.shared.cosineSimilarity(a: queryEmbedding, b: embedding)
                // Threshold to avoid returning completely irrelevant items
                if score > 0.4 {
                    scoredEntries.append((entry, score))
                }
            }
        }
        
        scoredEntries.sort { $0.score > $1.score }
        
        return scoredEntries.prefix(limit).map { $0.entry }
    }

    /// Fetch all entries marked as favorites.
    ///
    /// - Returns: Favorite entries ordered by timestamp descending.
    func fetchFavorites() throws -> [ClipboardEntry] {
        try reader.read { db in
            try ClipboardEntry
                .filter(Column("isFavorite") == true)
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    /// Fetch all entries belonging to a specific collection.
    ///
    /// - Parameter collectionId: The UUID string of the target collection.
    /// - Returns: Matching entries ordered by timestamp descending.
    func fetchEntriesByCollection(_ collectionId: String) throws -> [ClipboardEntry] {
        try reader.read { db in
            try ClipboardEntry
                .filter(Column("collectionId") == collectionId)
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    /// Toggle the `isFavorite` flag on an entry.
    ///
    /// - Parameter id: UUID string of the target entry.
    func toggleFavorite(id: String) throws {
        try writer.write { db in
            if var entry = try ClipboardEntry.fetchOne(db, id: id) {
                entry.isFavorite.toggle()
                try entry.update(db)
            }
        }
    }

    /// Toggle the `isPinned` flag on an entry.
    ///
    /// - Parameter id: UUID string of the target entry.
    func togglePin(id: String) throws {
        try writer.write { db in
            if var entry = try ClipboardEntry.fetchOne(db, id: id) {
                entry.isPinned.toggle()
                try entry.update(db)
            }
        }
    }

    /// Move an entry into (or out of) a collection.
    ///
    /// - Parameters:
    ///   - entryId: UUID string of the entry to move.
    ///   - collectionId: Target collection UUID, or `nil` to remove
    ///     from all collections.
    func moveToCollection(entryId: String, collectionId: String?) throws {
        try writer.write { db in
            if var entry = try ClipboardEntry.fetchOne(db, id: entryId) {
                let previousCollectionId = entry.collectionId
                entry.collectionId = collectionId
                try entry.update(db)

                // Refresh denormalized counts on affected collections.
                if let previous = previousCollectionId {
                    try updateCollectionCountInTransaction(db, id: previous)
                }
                if let newId = collectionId {
                    try updateCollectionCountInTransaction(db, id: newId)
                }
            }
        }
    }

    /// Total number of clipboard entries in the database.
    func entryCount() throws -> Int {
        try reader.read { db in
            try ClipboardEntry.fetchCount(db)
        }
    }

    /// Number of clipboard entries captured today.
    func todayCount() throws -> Int {
        try reader.read { db in
            let startOfDay = Calendar.current.startOfDay(for: Date())
            return try ClipboardEntry
                .filter(Column("timestamp") >= startOfDay)
                .fetchCount(db)
        }
    }

    /// Aggregate counts grouped by content type category.
    ///
    /// - Returns: Array of `(categoryRawValue, count)` tuples sorted
    ///   by count descending.
    func categoryCounts() throws -> [(String, Int)] {
        try reader.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT contentType, COUNT(*) as cnt
                FROM clipboardEntries
                GROUP BY contentType
                ORDER BY cnt DESC
                """)
            return rows.map { row in
                let type: String = row["contentType"]
                let count: Int = row["cnt"]
                return (type, count)
            }
        }
    }

    // MARK: - Collection CRUD

    /// Insert a new collection.
    ///
    /// - Parameter collection: The collection to persist.
    func insertCollection(_ collection: Collection) throws {
        try writer.write { db in
            try collection.insert(db)
        }
    }

    /// Delete a collection by its identifier.
    ///
    /// Entries that belonged to this collection will have their
    /// `collectionId` set to `NULL` (via the foreign key ON DELETE SET NULL).
    ///
    /// - Parameter id: UUID string of the collection to remove.
    func deleteCollection(id: String) throws {
        try writer.write { db in
            _ = try Collection.deleteOne(db, id: id)
        }
    }

    /// Fetch all collections ordered by creation date.
    ///
    /// - Returns: All `Collection` records.
    func fetchCollections() throws -> [Collection] {
        try reader.read { db in
            try Collection
                .order(Column("createdAt").asc)
                .fetchAll(db)
        }
    }

    /// Refresh the denormalized `itemCount` on a collection.
    ///
    /// - Parameter id: UUID string of the collection to update.
    func updateCollectionCount(id: String) throws {
        try writer.write { db in
            try updateCollectionCountInTransaction(db, id: id)
        }
    }

    // MARK: - Private Helpers

    /// Internal helper that recalculates and writes the item count
    /// for a collection inside an already-open transaction.
    private func updateCollectionCountInTransaction(_ db: Database, id: String) throws {
        let count = try ClipboardEntry
            .filter(Column("collectionId") == id)
            .fetchCount(db)
        try db.execute(
            sql: "UPDATE collections SET itemCount = ? WHERE id = ?",
            arguments: [count, id]
        )
    }
}
