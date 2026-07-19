//
//  Migrations.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import GRDB

/// Database schema migrations for the ClipB application.
///
/// Each migration is registered with a unique identifier and run exactly
/// once. GRDB tracks which migrations have been applied in an internal
/// metadata table, so adding new migrations is always additive.
struct AppMigrations {

    /// Registers all known migrations on the given migrator.
    ///
    /// Call this before opening the database so that the schema is
    /// up-to-date when the first query executes.
    ///
    /// - Parameter migrator: The GRDB `DatabaseMigrator` to register on.
    static func registerMigrations(_ migrator: inout DatabaseMigrator) {

        // ──────────────────────────────────────────────
        // MARK: v1 – Initial schema
        // ──────────────────────────────────────────────
        migrator.registerMigration("v1_createTables") { db in

            // ── collections ──
            try db.create(table: "collections") { table in
                table.primaryKey("id", .text).notNull()
                table.column("name", .text).notNull()
                table.column("icon", .text).notNull()
                table.column("colorName", .text).notNull()
                table.column("createdAt", .datetime).notNull()
                    .defaults(sql: "CURRENT_TIMESTAMP")
                table.column("itemCount", .integer).notNull()
                    .defaults(to: 0)
            }

            // ── clipboardEntries ──
            try db.create(table: "clipboardEntries") { table in
                table.primaryKey("id", .text).notNull()
                table.column("timestamp", .datetime).notNull()
                    .defaults(sql: "CURRENT_TIMESTAMP")
                table.column("contentType", .text).notNull()
                table.column("textContent", .text)
                table.column("imageData", .blob)
                table.column("preview", .text).notNull()
                    .defaults(to: "")
                table.column("category", .text)
                table.column("tags", .text)
                table.column("aiSummary", .text)
                table.column("isFavorite", .boolean).notNull()
                    .defaults(to: false)
                table.column("isPinned", .boolean).notNull()
                    .defaults(to: false)
                table.column("isEncrypted", .boolean).notNull()
                    .defaults(to: false)
                table.column("collectionId", .text)
                    .references("collections", onDelete: .setNull)
                table.column("sourceApp", .text)
            }

            // ── FTS5 virtual table for full-text search ──
            try db.create(virtualTable: "clipboardEntries_fts", using: FTS5()) { fts in
                fts.synchronize(withTable: "clipboardEntries")
                fts.tokenizer = .unicode61()
                fts.column("textContent")
                fts.column("preview")
                fts.column("category")
                fts.column("tags")
                fts.column("aiSummary")
            }

            // ── Indexes ──
            try db.create(
                index: "idx_clipboardEntries_timestamp",
                on: "clipboardEntries",
                columns: ["timestamp"],
                options: .unique.union([])  // non-unique
            )
            try db.create(
                index: "idx_clipboardEntries_contentType",
                on: "clipboardEntries",
                columns: ["contentType"]
            )
            try db.create(
                index: "idx_clipboardEntries_isFavorite",
                on: "clipboardEntries",
                columns: ["isFavorite"]
            )
            try db.create(
                index: "idx_clipboardEntries_collectionId",
                on: "clipboardEntries",
                columns: ["collectionId"]
            )
            try db.create(
                index: "idx_clipboardEntries_isPinned",
                on: "clipboardEntries",
                columns: ["isPinned"]
            )
        }
        
        // ──────────────────────────────────────────────
        // MARK: v2 – Add local embedding
        // ──────────────────────────────────────────────
        migrator.registerMigration("v2_addEmbedding") { db in
            try db.alter(table: "clipboardEntries") { table in
                table.add(column: "embedding", .blob)
            }
        }
    }
}
