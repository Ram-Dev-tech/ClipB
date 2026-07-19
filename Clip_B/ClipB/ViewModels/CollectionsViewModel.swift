//
//  CollectionsViewModel.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - CollectionsViewModel

/// Manages the lifecycle of user-created collections, including
/// listing, creating, deleting, and selecting collections.
///
/// Collections act as folders that users can organise clipboard
/// entries into. Each collection has a name, an SF Symbol icon,
/// and a color for visual identification.
///
/// ## Usage
/// ```swift
/// @StateObject var vm = CollectionsViewModel()
/// vm.newCollectionName = "Work Notes"
/// vm.createCollection()
/// ```
@MainActor
final class CollectionsViewModel: ObservableObject {

    // MARK: - Published State

    /// All collections fetched from the database.
    @Published var collections: [Collection] = []

    /// The currently selected collection, if any. Drives the
    /// detail view showing entries within a collection.
    @Published var selectedCollection: Collection?

    /// Whether the "create new collection" sheet/popover is shown.
    @Published var isCreatingNew: Bool = false

    /// The name for the collection being created.
    @Published var newCollectionName: String = ""

    /// The SF Symbol icon name for the collection being created.
    @Published var newCollectionIcon: String = "folder"

    /// The color identifier for the collection being created.
    @Published var newCollectionColor: String = "blue"

    // MARK: - Initialization

    init() {
        loadCollections()
    }

    // MARK: - Public API

    /// Fetches all collections from the database and updates the
    /// published `collections` array.
    func loadCollections() {
        do {
            collections = try DatabaseManager.shared.fetchCollections()
        } catch {
            print("[ClipB] Error loading collections: \(error.localizedDescription)")
        }
    }

    /// Creates a new collection from the current `newCollectionName`,
    /// `newCollectionIcon`, and `newCollectionColor` values.
    ///
    /// After successful creation the input fields are reset and the
    /// collections list is refreshed.
    func createCollection() {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let collection = Collection(
            id: UUID().uuidString,
            name: name,
            icon: newCollectionIcon,
            colorName: newCollectionColor,
            createdAt: Date(),
            itemCount: 0
        )

        do {
            try DatabaseManager.shared.insertCollection(collection)
            resetCreationFields()
            isCreatingNew = false
            loadCollections()
        } catch {
            print("[ClipB] Error creating collection '\(name)': \(error.localizedDescription)")
        }
    }

    /// Deletes a collection from the database. If the deleted
    /// collection was selected, the selection is cleared.
    ///
    /// - Parameter collection: The collection to delete.
    func deleteCollection(_ collection: Collection) {
        do {
            try DatabaseManager.shared.deleteCollection(id: collection.id)
            if selectedCollection?.id == collection.id {
                selectedCollection = nil
            }
            loadCollections()
        } catch {
            print("[ClipB] Error deleting collection '\(collection.name)': \(error.localizedDescription)")
        }
    }

    /// Selects a collection, triggering the detail view to display
    /// the entries within it.
    ///
    /// - Parameter collection: The collection to select.
    func selectCollection(_ collection: Collection) {
        selectedCollection = collection
    }

    // MARK: - Private Helpers

    /// Resets the new-collection input fields to their defaults.
    private func resetCreationFields() {
        newCollectionName = ""
        newCollectionIcon = "folder"
        newCollectionColor = "blue"
    }
}
