//
//  WidgetDataSharingService.swift
//  fig
//
//  Manages pre-computed widget data sharing between app and widget extension
//  Uses App Group container for efficient data transfer
//

import Foundation
import SwiftUI
import SwiftData

/// Service for sharing pre-computed alarm data between app and widget
struct WidgetDataSharingService {

    // MARK: - Constants

    private static let appGroupIdentifier = "group.m.fig"
    private static let cacheFileName = "widget-alarm-cache.json"

    // MARK: - Cache Model

    /// Wrapper for cached alarm data with metadata
    struct CachedAlarmData: Codable {
        let alarms: [UpcomingAlarmPresentation]
        let computedAt: Date
        let version: Int

        init(alarms: [UpcomingAlarmPresentation], computedAt: Date = Date(), version: Int = 1) {
            self.alarms = alarms
            self.computedAt = computedAt
            self.version = version
        }
    }

    // MARK: - Public Methods

    /// Updates the shared widget data cache with pre-computed alarms
    /// Call this from the main app whenever alarms change
    /// - Parameters:
    ///   - context: SwiftData model context for fetching alarms
    ///   - limit: Maximum number of alarms to cache
    ///   - withinHours: Time window for upcoming alarms
    static func updateSharedCache(context: ModelContext, limit: Int = 10, withinHours: Int = 24) async {
        // Compute upcoming alarms (reusing WidgetDataFetcher logic but in app context)
        let alarms = await computeUpcomingAlarms(context: context, limit: limit, withinHours: withinHours)

        // Write to cache
        do {
            try writeToCache(alarms: alarms)
            print("📦 WidgetDataSharingService: Successfully cached \(alarms.count) Tickers")
        } catch {
            print("⚠️ WidgetDataSharingService: Failed to write cache: \(error)")
        }
    }

    /// Reads cached alarm data from the shared container
    /// Returns nil if cache doesn't exist or is invalid
    /// - Parameter maxAge: Maximum age of cache in seconds (default: 5 minutes)
    /// - Returns: Cached alarms if valid, nil otherwise
    static func readFromCache(maxAge: TimeInterval = 300) -> [UpcomingAlarmPresentation]? {
        guard let fileURL = cacheFileURL() else {
            print("⚠️ WidgetDataSharingService: Unable to get cache file URL")
            return nil
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ WidgetDataSharingService: Cache file does not exist")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let cachedData = try decoder.decode(CachedAlarmData.self, from: data)

            // Check if cache is fresh
            let age = Date().timeIntervalSince(cachedData.computedAt)
            guard age <= maxAge else {
                print("ℹ️ WidgetDataSharingService: Cache expired (age: \(Int(age))s, max: \(Int(maxAge))s)")
                return nil
            }

            print("✅ WidgetDataSharingService: Read \(cachedData.alarms.count) alarms from cache (age: \(Int(age))s)")
            return cachedData.alarms

        } catch {
            print("⚠️ WidgetDataSharingService: Failed to read cache: \(error)")
            return nil
        }
    }

    /// Clears the cached alarm data
    static func clearCache() {
        guard let fileURL = cacheFileURL() else { return }
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ WidgetDataSharingService: Cache cleared")
    }

    // MARK: - Private Helpers

    /// Returns the URL for the cache file in the App Group container
    private static func cacheFileURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }
        return containerURL.appendingPathComponent(cacheFileName)
    }

    /// Writes alarm data to the cache file
    private static func writeToCache(alarms: [UpcomingAlarmPresentation]) throws {
        guard let fileURL = cacheFileURL() else {
            throw NSError(domain: "WidgetDataSharingService", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Unable to get cache file URL"])
        }

        let cachedData = CachedAlarmData(alarms: alarms)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(cachedData)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Computes upcoming alarms from SwiftData using centralized service
    private static func computeUpcomingAlarms(
        context: ModelContext,
        limit: Int,
        withinHours: Int
    ) async -> [UpcomingAlarmPresentation] {
        return await AlarmOccurrenceService.computeOccurrences(
            context: context,
            withinHours: withinHours,
            limit: limit
        )
    }

}
