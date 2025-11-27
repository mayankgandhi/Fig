//
//  CollectionChildTickerData.swift
//  fig
//
//  Intermediate data structure for child tickers before Ticker creation
//  Used in TickerCollectionEditor to defer Ticker creation until final save
//

import Foundation
import TickerCore

/// Lightweight data structure representing a child ticker before conversion to Ticker
/// Used in TickerCollectionEditor to defer Ticker creation until final save
struct CollectionChildTickerData: Identifiable, Hashable {
    let id: UUID
    var label: String
    var schedule: TickerSchedule

    init(id: UUID = UUID(), label: String, schedule: TickerSchedule) {
        self.id = id
        self.label = label
        self.schedule = schedule
    }

    /// Convert to Ticker with inherited configuration from collection
    /// All child tickers inherit presentation, sound (default), and no countdown
    func toTicker(presentation: TickerPresentation, icon: String, colorHex: String) -> Ticker {
        return Ticker(
            label: label,
            isEnabled: true,
            schedule: schedule,
            countdown: nil, // No countdown for collection children
            presentation: presentation,
            soundName: nil, // Use system default
            tickerData: TickerData(
                name: label,
                icon: icon,
                colorHex: colorHex
            )
        )
    }
}
