//
//  IconMetadata.swift
//  TickerCore
//
//  Provides accessible labels for SF Symbols used in the app.
//  Maps system icon names to human-readable descriptions for VoiceOver.
//

import Foundation

/// Accessibility metadata for SF Symbols
public struct IconMetadata {
    /// Dictionary mapping SF Symbol names to accessible labels
    public static let accessibleLabels: [String: String] = [
        // Alarms & Time
        "alarm": "Alarm",
        "alarm.fill": "Alarm",
        "clock": "Clock",
        "clock.fill": "Clock",
        "calendar": "Calendar",
        "calendar.circle.fill": "Calendar",
        "timer": "Timer",
        "hourglass": "Hourglass",

        // Activities
        "figure.run": "Running or exercise",
        "figure.run.circle.fill": "Running or exercise",
        "figure.yoga": "Yoga",
        "figure.walk": "Walking",
        "heart.fill": "Health or favorite",
        "waveform.path.ecg": "Heart rate or health monitoring",
        "drop.fill": "Water or hydration",
        "flame.fill": "Calories or intensity",
        "figure.strengthtraining.traditional": "Strength training",

        // Work & Tasks
        "briefcase.fill": "Work or business",
        "checkmark.circle.fill": "Task completed or checked",
        "book.fill": "Reading or study",
        "lightbulb.fill": "Idea or inspiration",
        "pencil.circle.fill": "Writing or editing",
        "laptopcomputer": "Computer or work",
        "doc.text.fill": "Document or notes",

        // Wellness
        "moon.stars.fill": "Sleep or night time",
        "sun.max.fill": "Wake up or morning",
        "leaf.fill": "Nature or relaxation",
        "pills.fill": "Medicine or medication",
        "cross.case.fill": "Medical or first aid",
        "sparkles": "Special or celebration",
        "bed.double.fill": "Sleep or bedtime",

        // Food & Drink
        "fork.knife": "Meal or dining",
        "cup.and.saucer.fill": "Coffee or tea break",
        "carrot.fill": "Healthy food or snack",
        "takeoutbag.and.cup.and.straw.fill": "Takeout or fast food",
        "mug.fill": "Coffee or hot beverage",

        // Communication
        "bell.fill": "Notification or reminder",
        "phone.fill": "Phone call",
        "message.fill": "Message or text",
        "envelope.fill": "Email or mail",
        "bubble.left.and.bubble.right.fill": "Conversation or chat",

        // Common UI Elements
        "gear": "Settings",
        "apple.intelligence": "AI or smart features",
        "pencil": "Edit",
        "trash": "Delete",
        "plus": "Add",
        "xmark": "Close or cancel",
        "chevron.right": "Next or forward",
        "chevron.left": "Back or previous",
        "ellipsis": "More options"
    ]

    /// Get accessible label for a given SF Symbol name
    /// - Parameter symbol: The SF Symbol system name
    /// - Returns: Accessible label, or the symbol name if no mapping exists
    public static func accessibleLabel(for symbol: String) -> String {
        accessibleLabels[symbol] ?? symbol.replacingOccurrences(of: ".", with: " ")
    }
}
