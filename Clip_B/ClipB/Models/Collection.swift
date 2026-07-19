//
//  Collection.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation
import GRDB

/// A user-created collection (folder) for organizing clipboard entries.
///
/// Collections let users group related entries together — for example,
/// "Work", "Research", or "Recipes". Each collection stores a
/// denormalized `itemCount` that is refreshed whenever entries are
/// added or removed.
struct Collection: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {

    // MARK: - Stored Properties

    /// Unique identifier (UUID string).
    var id: String

    /// User-visible collection name.
    var name: String

    /// SF Symbol name used as the collection icon.
    var icon: String

    /// SwiftUI color name used for tinting the icon and badges.
    var colorName: String

    /// When the collection was created.
    var createdAt: Date

    /// Denormalized count of entries in this collection.
    var itemCount: Int

    // MARK: - Table Mapping

    /// GRDB table name.
    static let databaseTableName = "collections"

    // MARK: - Initialiser

    /// Creates a new `Collection` with sensible defaults.
    ///
    /// - Parameters:
    ///   - id: UUID string. Defaults to a new UUID.
    ///   - name: Collection display name.
    ///   - icon: SF Symbol name.
    ///   - colorName: SwiftUI color name.
    ///   - createdAt: Creation date. Defaults to now.
    ///   - itemCount: Initial item count. Defaults to 0.
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        colorName: String,
        createdAt: Date = Date(),
        itemCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.createdAt = createdAt
        self.itemCount = itemCount
    }

    // MARK: - Default Collections

    /// Preset collections shipped with a fresh install.
    ///
    /// These are inserted into the database on first launch so the user
    /// has useful organizational buckets out of the box.
    static let defaultCollections: [Collection] = [
        Collection(
            name: "Work",
            icon: "briefcase.fill",
            colorName: "blue"
        ),
        Collection(
            name: "Programming",
            icon: "chevron.left.forwardslash.chevron.right",
            colorName: "indigo"
        ),
        Collection(
            name: "University",
            icon: "graduationcap.fill",
            colorName: "purple"
        ),
        Collection(
            name: "Research",
            icon: "magnifyingglass",
            colorName: "teal"
        ),
        Collection(
            name: "Passwords",
            icon: "lock.fill",
            colorName: "red"
        ),
        Collection(
            name: "Recipes",
            icon: "fork.knife",
            colorName: "orange"
        ),
        Collection(
            name: "Ideas",
            icon: "lightbulb.fill",
            colorName: "yellow"
        ),
        Collection(
            name: "Shopping",
            icon: "cart.fill",
            colorName: "green"
        ),
    ]
}
