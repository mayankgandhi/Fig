//
//  IconColorPair.swift
//  fig
//
//  Icon-color mapping for SF Symbols picker
//  Provides curated list of symbols with predefined colors
//

import Foundation
import SwiftUI

// MARK: - IconColorPair Model

struct IconColorPair: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let colorHex: String
    let category: IconCategory

    var color: Color {
        Color(hex: colorHex) ?? TickerColor.primary
    }

    enum IconCategory: String, CaseIterable {
        case general = "General"
    }
}

// MARK: - Curated Icon Collection

extension IconColorPair {

    /// Curated collection of icon-color pairs
    static let allIcons: [IconColorPair] = [
        // Alarms & Time
        IconColorPair(symbol: "alarm", colorHex: "#8B5CF6", category: .general),
        IconColorPair(symbol: "alarm.fill", colorHex: "#8B5CF6", category: .general),
        IconColorPair(symbol: "clock", colorHex: "#3B82F6", category: .general),
        IconColorPair(symbol: "clock.fill", colorHex: "#3B82F6", category: .general),
        IconColorPair(symbol: "calendar", colorHex: "#0EA5E9", category: .general),
        IconColorPair(symbol: "calendar.circle.fill", colorHex: "#0EA5E9", category: .general),
        IconColorPair(symbol: "timer", colorHex: "#F59E0B", category: .general),
        IconColorPair(symbol: "hourglass", colorHex: "#F59E0B", category: .general),

        // Activities
        IconColorPair(symbol: "figure.run", colorHex: "#FF6B35", category: .general),
        IconColorPair(symbol: "figure.run.circle.fill", colorHex: "#FF6B35", category: .general),
        IconColorPair(symbol: "figure.yoga", colorHex: "#84CC16", category: .general),
        IconColorPair(symbol: "figure.walk", colorHex: "#10B981", category: .general),
        IconColorPair(symbol: "heart.fill", colorHex: "#E91E63", category: .general),
        IconColorPair(symbol: "waveform.path.ecg", colorHex: "#EF4444", category: .general),
        IconColorPair(symbol: "drop.fill", colorHex: "#06B6D4", category: .general),
        IconColorPair(symbol: "flame.fill", colorHex: "#F97316", category: .general),
        IconColorPair(symbol: "figure.strengthtraining.traditional", colorHex: "#DC2626", category: .general),

        // Work & Tasks
        IconColorPair(symbol: "briefcase.fill", colorHex: "#4CAF50", category: .general),
        IconColorPair(symbol: "checkmark.circle.fill", colorHex: "#10B981", category: .general),
        IconColorPair(symbol: "book.fill", colorHex: "#6366F1", category: .general),
        IconColorPair(symbol: "lightbulb.fill", colorHex: "#F59E0B", category: .general),
        IconColorPair(symbol: "pencil.circle.fill", colorHex: "#8B5CF6", category: .general),
        IconColorPair(symbol: "laptopcomputer", colorHex: "#64748B", category: .general),
        IconColorPair(symbol: "doc.text.fill", colorHex: "#3B82F6", category: .general),

        // Wellness
        IconColorPair(symbol: "moon.stars.fill", colorHex: "#3B82F6", category: .general),
        IconColorPair(symbol: "sun.max.fill", colorHex: "#FCD34D", category: .general),
        IconColorPair(symbol: "leaf.fill", colorHex: "#22C55E", category: .general),
        IconColorPair(symbol: "pills.fill", colorHex: "#14B8A6", category: .general),
        IconColorPair(symbol: "cross.case.fill", colorHex: "#DC2626", category: .general),
        IconColorPair(symbol: "sparkles", colorHex: "#D946EF", category: .general),
        IconColorPair(symbol: "bed.double.fill", colorHex: "#6366F1", category: .general),

        // Food & Drink
        IconColorPair(symbol: "fork.knife", colorHex: "#FB923C", category: .general),
        IconColorPair(symbol: "cup.and.saucer.fill", colorHex: "#92400E", category: .general),
        IconColorPair(symbol: "carrot.fill", colorHex: "#F97316", category: .general),
        IconColorPair(symbol: "takeoutbag.and.cup.and.straw.fill", colorHex: "#DC2626", category: .general),
        IconColorPair(symbol: "mug.fill", colorHex: "#78350F", category: .general),

        // Communication
        IconColorPair(symbol: "bell.fill", colorHex: "#D946EF", category: .general),
        IconColorPair(symbol: "phone.fill", colorHex: "#10B981", category: .general),
        IconColorPair(symbol: "message.fill", colorHex: "#3B82F6", category: .general),
        IconColorPair(symbol: "envelope.fill", colorHex: "#F59E0B", category: .general),
        IconColorPair(symbol: "bubble.left.and.bubble.right.fill", colorHex: "#06B6D4", category: .general),
    ]

    /// Icons grouped by category for organized display
    static let iconsByCategory: [IconCategory: [IconColorPair]] = {
        Dictionary(grouping: allIcons, by: { $0.category })
    }()

    /// Get a specific icon-color pair by symbol name
    static func icon(for symbol: String) -> IconColorPair? {
        allIcons.first { $0.symbol == symbol }
    }

    /// Default icon-color pair (alarm with purple)
    static let defaultIcon = IconColorPair(symbol: "alarm", colorHex: "#8B5CF6", category: .general)
}
