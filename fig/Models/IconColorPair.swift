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
        Color(hex: colorHex) ?? TickerColors.primary
    }

    enum IconCategory: String, CaseIterable {
        case time = "Time & Scheduling"
        case fitness = "Fitness & Health"
        case work = "Work & Productivity"
        case wellness = "Wellness & Self-care"
        case food = "Food & Nutrition"
        case communication = "Communication"
    }
}

// MARK: - Curated Icon Collection

extension IconColorPair {

    /// Curated collection of icon-color pairs organized by category
    static let allIcons: [IconColorPair] = [

        // MARK: Time & Scheduling
        IconColorPair(symbol: "alarm", colorHex: "#8B5CF6", category: .time),
        IconColorPair(symbol: "alarm.fill", colorHex: "#8B5CF6", category: .time),
        IconColorPair(symbol: "clock", colorHex: "#3B82F6", category: .time),
        IconColorPair(symbol: "clock.fill", colorHex: "#3B82F6", category: .time),
        IconColorPair(symbol: "calendar", colorHex: "#0EA5E9", category: .time),
        IconColorPair(symbol: "calendar.circle.fill", colorHex: "#0EA5E9", category: .time),
        IconColorPair(symbol: "timer", colorHex: "#F59E0B", category: .time),
        IconColorPair(symbol: "hourglass", colorHex: "#F59E0B", category: .time),

        // MARK: Fitness & Health
        IconColorPair(symbol: "figure.run", colorHex: "#FF6B35", category: .fitness),
        IconColorPair(symbol: "figure.run.circle.fill", colorHex: "#FF6B35", category: .fitness),
        IconColorPair(symbol: "figure.yoga", colorHex: "#84CC16", category: .fitness),
        IconColorPair(symbol: "figure.walk", colorHex: "#10B981", category: .fitness),
        IconColorPair(symbol: "heart.fill", colorHex: "#E91E63", category: .fitness),
        IconColorPair(symbol: "waveform.path.ecg", colorHex: "#EF4444", category: .fitness),
        IconColorPair(symbol: "drop.fill", colorHex: "#06B6D4", category: .fitness),
        IconColorPair(symbol: "flame.fill", colorHex: "#F97316", category: .fitness),
        IconColorPair(symbol: "figure.strengthtraining.traditional", colorHex: "#DC2626", category: .fitness),

        // MARK: Work & Productivity
        IconColorPair(symbol: "briefcase.fill", colorHex: "#4CAF50", category: .work),
        IconColorPair(symbol: "checkmark.circle.fill", colorHex: "#10B981", category: .work),
        IconColorPair(symbol: "book.fill", colorHex: "#6366F1", category: .work),
        IconColorPair(symbol: "lightbulb.fill", colorHex: "#F59E0B", category: .work),
        IconColorPair(symbol: "pencil.circle.fill", colorHex: "#8B5CF6", category: .work),
        IconColorPair(symbol: "laptopcomputer", colorHex: "#64748B", category: .work),
        IconColorPair(symbol: "doc.text.fill", colorHex: "#3B82F6", category: .work),

        // MARK: Wellness & Self-care
        IconColorPair(symbol: "moon.stars.fill", colorHex: "#3B82F6", category: .wellness),
        IconColorPair(symbol: "sun.max.fill", colorHex: "#FCD34D", category: .wellness),
        IconColorPair(symbol: "leaf.fill", colorHex: "#22C55E", category: .wellness),
        IconColorPair(symbol: "pills.fill", colorHex: "#14B8A6", category: .wellness),
        IconColorPair(symbol: "cross.case.fill", colorHex: "#DC2626", category: .wellness),
        IconColorPair(symbol: "sparkles", colorHex: "#D946EF", category: .wellness),
        IconColorPair(symbol: "bed.double.fill", colorHex: "#6366F1", category: .wellness),

        // MARK: Food & Nutrition
        IconColorPair(symbol: "fork.knife", colorHex: "#FB923C", category: .food),
        IconColorPair(symbol: "cup.and.saucer.fill", colorHex: "#92400E", category: .food),
        IconColorPair(symbol: "carrot.fill", colorHex: "#F97316", category: .food),
        IconColorPair(symbol: "takeoutbag.and.cup.and.straw.fill", colorHex: "#DC2626", category: .food),
        IconColorPair(symbol: "mug.fill", colorHex: "#78350F", category: .food),

        // MARK: Communication
        IconColorPair(symbol: "bell.fill", colorHex: "#D946EF", category: .communication),
        IconColorPair(symbol: "phone.fill", colorHex: "#10B981", category: .communication),
        IconColorPair(symbol: "message.fill", colorHex: "#3B82F6", category: .communication),
        IconColorPair(symbol: "envelope.fill", colorHex: "#F59E0B", category: .communication),
        IconColorPair(symbol: "bubble.left.and.bubble.right.fill", colorHex: "#06B6D4", category: .communication),
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
    static let defaultIcon = IconColorPair(symbol: "alarm", colorHex: "#8B5CF6", category: .time)
}
