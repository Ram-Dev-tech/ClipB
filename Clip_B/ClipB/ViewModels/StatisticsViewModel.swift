//
//  StatisticsViewModel.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - StatisticsViewModel

/// Aggregates and exposes clipboard usage statistics for the
/// dashboard and statistics views.
///
/// Data is pulled from `DatabaseManager.shared` and supplemented
/// with derived metrics like storage size and weekly activity.
///
/// ## Refresh
/// Call `refresh()` to reload all statistics. This is typically
/// invoked on view appearance and after significant data changes.
@MainActor
final class StatisticsViewModel: ObservableObject {

    // MARK: - Published State

    /// Number of clipboard entries captured today.
    @Published var todayCopies: Int = 0

    /// Total number of entries stored in the database.
    @Published var totalEntries: Int = 0

    /// Number of entries marked as favorites.
    @Published var favoriteCount: Int = 0

    /// Breakdown of entries by content-type category.
    /// Each tuple contains the category display name and its count.
    @Published var categoryCounts: [(category: String, count: Int)] = []

    /// Daily activity data for the last 7 days, used to drive
    /// the weekly activity chart.
    @Published var weeklyActivity: [DailyActivity] = []

    /// Human-readable string for total storage consumed by the
    /// database file (e.g. "24.7 MB").
    @Published var storageUsed: String = "0 MB"

    // MARK: - DailyActivity

    /// Represents clipboard activity for a single day.
    struct DailyActivity: Identifiable, Sendable {
        let id = UUID()

        /// The calendar date this activity corresponds to.
        let date: Date

        /// Number of clipboard captures on this date.
        let count: Int

        /// Short day-of-week label (e.g. "Mon", "Tue").
        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    // MARK: - Initialization

    init() {
        refresh()
    }

    // MARK: - Public API

    /// Reloads all statistics from the database and recalculates
    /// derived metrics.
    func refresh() {
        loadCounts()
        loadCategoryCounts()
        generateWeeklyActivity()
        storageUsed = calculateStorageSize()
    }

    // MARK: - Private Helpers

    /// Loads scalar count metrics from the database.
    private func loadCounts() {
        do {
            totalEntries = try DatabaseManager.shared.entryCount()
            todayCopies = try DatabaseManager.shared.todayCount()
            let favorites = try DatabaseManager.shared.fetchFavorites()
            favoriteCount = favorites.count
        } catch {
            print("[ClipB] Error loading statistics counts: \(error.localizedDescription)")
        }
    }

    /// Loads the per-category entry counts from the database.
    private func loadCategoryCounts() {
        do {
            let counts = try DatabaseManager.shared.categoryCounts()
            // `categoryCounts()` returns [(String, Int)] or similar
            categoryCounts = counts.map { (category: $0.0, count: $0.1) }
        } catch {
            print("[ClipB] Error loading category counts: \(error.localizedDescription)")
        }
    }

    /// Generates daily activity data for the last 7 days.
    ///
    /// Uses placeholder random counts (5–50) because per-day
    /// query support is not yet available. This will be replaced
    /// with real data in a future phase.
    private func generateWeeklyActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        weeklyActivity = (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return nil
            }
            // Placeholder: deterministic-looking random count
            // seeded from the day-of-year for visual consistency
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
            let count = 5 + (dayOfYear * 7 + daysAgo * 13) % 46  // range 5–50
            return DailyActivity(date: date, count: count)
        }
    }

    /// Calculates the current database file size as a human-readable
    /// string.
    ///
    /// - Returns: A formatted size string such as "12.4 MB",
    ///   or "0 MB" if the file cannot be read.
    private func calculateStorageSize() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first

        // Check both the custom path and the default location
        let possiblePaths: [URL] = [
            appSupport?
                .appendingPathComponent("ClipB", isDirectory: true)
                .appendingPathComponent("ClipB.sqlite")
        ].compactMap { $0 }

        for url in possiblePaths {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? Int64 {
                    return ByteCountFormatter.string(
                        fromByteCount: fileSize,
                        countStyle: .file
                    )
                }
            } catch {
                continue
            }
        }

        return "0 MB"
    }
}
