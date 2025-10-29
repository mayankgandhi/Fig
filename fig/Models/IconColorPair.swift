//
//  IconColorPair.swift
//  fig
//
//  Icon-color mapping for SF Symbols picker
//  Provides curated list of symbols with predefined colors
//

import Foundation
import SwiftUI
import TickerCore

// MARK: - IconColorPair Model

struct IconColorPair: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let colorHex: String

    var color: Color {
        Color(hex: colorHex) ?? TickerColor.primary
    }

}

// MARK: - Curated Icon Collection

extension IconColorPair {

    /// Curated collection of icon-color pairs
    static let allIcons: [IconColorPair] = [
        // Alarms & Time
        IconColorPair(symbol: "alarm", colorHex: "#8B5CF6"),
        IconColorPair(symbol: "alarm.fill", colorHex: "#8B5CF6"),
        IconColorPair(symbol: "clock", colorHex: "#3B82F6"),
        IconColorPair(symbol: "clock.fill", colorHex: "#3B82F6"),
        IconColorPair(symbol: "calendar", colorHex: "#0EA5E9"),
        IconColorPair(symbol: "calendar.circle.fill", colorHex: "#0EA5E9"),
        IconColorPair(symbol: "timer", colorHex: "#F59E0B"),
        IconColorPair(symbol: "hourglass", colorHex: "#F59E0B"),

        // Activities
        IconColorPair(symbol: "figure.run", colorHex: "#FF6B35"),
        IconColorPair(symbol: "figure.run.circle.fill", colorHex: "#FF6B35"),
        IconColorPair(symbol: "figure.yoga", colorHex: "#84CC16"),
        IconColorPair(symbol: "figure.walk", colorHex: "#10B981"),
        IconColorPair(symbol: "heart.fill", colorHex: "#E91E63"),
        IconColorPair(symbol: "waveform.path.ecg", colorHex: "#EF4444"),
        IconColorPair(symbol: "drop.fill", colorHex: "#06B6D4"),
        IconColorPair(symbol: "flame.fill", colorHex: "#F97316"),
        IconColorPair(symbol: "figure.strengthtraining.traditional", colorHex: "#DC2626"),

        // Work & Tasks
        IconColorPair(symbol: "briefcase.fill", colorHex: "#4CAF50"),
        IconColorPair(symbol: "checkmark.circle.fill", colorHex: "#10B981"),
        IconColorPair(symbol: "book.fill", colorHex: "#6366F1"),
        IconColorPair(symbol: "lightbulb.fill", colorHex: "#F59E0B"),
        IconColorPair(symbol: "pencil.circle.fill", colorHex: "#8B5CF6"),
        IconColorPair(symbol: "laptopcomputer", colorHex: "#64748B"),
        IconColorPair(symbol: "doc.text.fill", colorHex: "#3B82F6"),

        // Wellness
        IconColorPair(symbol: "moon.stars.fill", colorHex: "#3B82F6"),
        IconColorPair(symbol: "sun.max.fill", colorHex: "#FCD34D"),
        IconColorPair(symbol: "leaf.fill", colorHex: "#22C55E"),
        IconColorPair(symbol: "pills.fill", colorHex: "#14B8A6"),
        IconColorPair(symbol: "cross.case.fill", colorHex: "#DC2626"),
        IconColorPair(symbol: "sparkles", colorHex: "#D946EF"),
        IconColorPair(symbol: "bed.double.fill", colorHex: "#6366F1"),

        // Food & Drink
        IconColorPair(symbol: "fork.knife", colorHex: "#FB923C"),
        IconColorPair(symbol: "cup.and.saucer.fill", colorHex: "#92400E"),
        IconColorPair(symbol: "carrot.fill", colorHex: "#F97316"),
        IconColorPair(symbol: "takeoutbag.and.cup.and.straw.fill", colorHex: "#DC2626"),
        IconColorPair(symbol: "mug.fill", colorHex: "#78350F"),

        // Communication
        IconColorPair(symbol: "bell.fill", colorHex: "#D946EF"),
        IconColorPair(symbol: "phone.fill", colorHex: "#10B981"),
        IconColorPair(symbol: "message.fill", colorHex: "#3B82F6"),
        IconColorPair(symbol: "envelope.fill", colorHex: "#F59E0B"),
        IconColorPair(symbol: "bubble.left.and.bubble.right.fill", colorHex: "#06B6D4"),
    ]

    /// Get a specific icon-color pair by symbol name
    static func icon(for symbol: String) -> IconColorPair? {
        allIcons.first { $0.symbol == symbol }
    }

    /// Default icon-color pair (alarm with purple)
    static let defaultIcon = IconColorPair(symbol: "alarm", colorHex: "#8B5CF6")
}
