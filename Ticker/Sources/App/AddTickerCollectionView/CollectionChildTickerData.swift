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
    // Optional customizations - if nil, uses collection defaults
    var icon: String?
    var colorHex: String?
    var soundName: String?
    var countdown: TickerCountdown?

    init(
        id: UUID = UUID(),
        label: String,
        schedule: TickerSchedule,
        icon: String? = nil,
        colorHex: String? = nil,
        soundName: String? = nil,
        countdown: TickerCountdown? = nil
    ) {
        self.id = id
        self.label = label
        self.schedule = schedule
        self.icon = icon
        self.colorHex = colorHex
        self.soundName = soundName
        self.countdown = countdown
    }

    /// Convert to Ticker with inherited configuration from collection
    /// Uses child-specific icon/sound/countdown if provided, otherwise falls back to collection defaults
    func toTicker(presentation: TickerPresentation, icon: String, colorHex: String, soundName: String?) -> Ticker {
        return Ticker(
            label: label,
            isEnabled: true,
            schedule: schedule,
            countdown: self.countdown, // Use child countdown if provided
            presentation: presentation,
            soundName: self.soundName ?? soundName, // Use child sound if provided, otherwise collection default
            tickerData: TickerData(
                name: label,
                icon: self.icon ?? icon, // Use child icon if provided, otherwise collection default
                colorHex: self.colorHex ?? colorHex // Use child color if provided, otherwise collection default
            )
        )
    }
}
