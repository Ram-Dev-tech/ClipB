//
//  TimelineSection.swift
//  ClipB
//
//  Created by ClipB on 2026-07-17.
//

import Foundation

/// Timeline grouping for clipboard history display.
///
/// Entries are bucketed into human-friendly time ranges so the history
/// list can show section headers like "Today", "Yesterday", etc.
enum TimelineSection: String, CaseIterable, Identifiable, Sendable {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case older

    /// Stable identifier for `Identifiable` conformance.
    var id: String { rawValue }

    /// Human-readable section header text.
    var displayName: String {
        switch self {
        case .today:     return "Today"
        case .yesterday: return "Yesterday"
        case .lastWeek:  return "Last 7 Days"
        case .lastMonth: return "Last 30 Days"
        case .older:     return "Older"
        }
    }

    /// Determine which section a given date belongs to.
    ///
    /// Uses the user's current calendar to compute boundaries so
    /// that "today" and "yesterday" respect locale-aware day starts.
    ///
    /// - Parameter date: The date to classify.
    /// - Returns: The appropriate `TimelineSection`.
    static func section(for date: Date) -> TimelineSection {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return .today
        }

        if calendar.isDateInYesterday(date) {
            return .yesterday
        }

        // Last 7 days (excluding today and yesterday, already handled)
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)),
           date >= sevenDaysAgo {
            return .lastWeek
        }

        // Last 30 days
        if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)),
           date >= thirtyDaysAgo {
            return .lastMonth
        }

        return .older
    }
}
