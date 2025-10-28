//
//  CreateAlarmAssistantIntent.swift
//  fig
//
//  Assistant Intent variant for proactive Siri suggestions
//

import Foundation
import AppIntents
import SwiftData
import SwiftUI

/// Assistant Intent variant that enables proactive Siri suggestions
@available(iOS 26.0, *)
struct CreateAlarmAssistantIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Create Ticker"
    static var description = IntentDescription("Create a new ticker alarm with intelligent suggestions")
    static var openAppWhenRun: Bool = false
    
    // MARK: - Parameters with Suggested Values
    
    @Parameter(title: "Time", description: "When the ticker should trigger")
    var time: Date
    
    @Parameter(title: "Label", description: "Name for the ticker")
    var label: String?
    
    @Parameter(title: "Repeat", description: "How often the ticker should repeat")
    var repeatFrequency: RepeatFrequencyEnum
    
    @Parameter(title: "Icon", description: "SF Symbol icon name")
    var icon: String?
    
    @Parameter(title: "Color", description: "Hex color for the ticker")
    var colorHex: String?
    
    @Parameter(title: "Sound", description: "Sound name for the ticker")
    var soundName: String?
    
    // MARK: - Suggested Values
    
    static var suggestedTimeValues: [Date] {
        // Suggest common wake-up times
        let calendar = Calendar.current
        let today = Date()
        
        return [
            calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today) ?? today,
            calendar.date(bySettingHour: 6, minute: 30, second: 0, of: today) ?? today,
            calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
            calendar.date(bySettingHour: 7, minute: 30, second: 0, of: today) ?? today,
            calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
            calendar.date(bySettingHour: 8, minute: 30, second: 0, of: today) ?? today
        ]
    }
    
    static var suggestedLabelValues: [String] {
        return [
            "Morning Wake Up",
            "Wake Up",
            "Morning Alarm",
            "Bedtime",
            "Work Alarm",
            "Exercise",
            "Meeting Reminder",
            "Medication",
            "Breakfast",
            "Coffee Time"
        ]
    }
    
    static var suggestedIconValues: [String] {
        return [
            "sunrise",
            "sun.max",
            "moon",
            "bed.double",
            "figure.run",
            "calendar",
            "pills",
            "cup.and.saucer",
            "alarm",
            "bell"
        ]
    }
    
    static var suggestedColorValues: [String] {
        return [
            "#FF6B6B", // Red
            "#4ECDC4", // Teal
            "#45B7D1", // Blue
            "#96CEB4", // Green
            "#FFEAA7", // Yellow
            "#DDA0DD", // Plum
            "#98D8C8", // Mint
            "#F7DC6F"  // Gold
        ]
    }
    
    static var suggestedSoundValues: [String] {
        return [
            "Default",
            "Gentle",
            "Chimes",
            "Bells",
            "Nature",
            "Ocean",
            "Rain",
            "Birds"
        ]
    }
    
    // MARK: - Initializers
    
    init() {
        self.time = Date()
        self.label = nil
        self.repeatFrequency = .oneTime
        self.icon = nil
        self.colorHex = nil
    }
    
    init(time: Date, label: String? = nil, repeatFrequency: RepeatFrequencyEnum = .oneTime, icon: String? = nil, colorHex: String? = nil, soundName: String? = nil) {
        self.time = time
        self.label = label
        self.repeatFrequency = repeatFrequency
        self.icon = icon
        self.colorHex = colorHex
        self.soundName = soundName
    }
    
    // MARK: - Intent Performance
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("🤖 CreateAlarmAssistantIntent.perform() started")
        print("   → time: \(time)")
        print("   → label: \(label ?? "nil")")
        print("   → repeatFrequency: \(repeatFrequency)")
        print("   → icon: \(icon ?? "nil")")
        print("   → colorHex: \(colorHex ?? "nil")")
        
        // Use the same logic as CreateAlarmIntent but with enhanced context
        let createIntent = CreateAlarmIntent(
            time: time,
            label: label,
            repeatFrequency: repeatFrequency,
            icon: icon,
            colorHex: colorHex,
            soundName: soundName
        )
        
        // Delegate to the main intent
        let result = try await createIntent.perform()
        
        // Additional donation for Assistant Intent learning
        await donateAssistantAction()
        
        return result
    }
    
    // MARK: - Assistant Learning
    
    private func donateAssistantAction() async {
        // Donate this action with rich context for Assistant learning
        do {
            try await self.donate()
            print("✅ Donated assistant action to SiriKit")
        } catch {
            print("⚠️ Failed to donate assistant action: \(error)")
        }
    }
    
    // MARK: - Contextual Suggestions
    
    static func contextualSuggestions(for context: String) -> [CreateAlarmAssistantIntent] {
        let calendar = Calendar.current
        let today = Date()
        
        switch context.lowercased() {
        case "morning", "wake up", "alarm":
            return [
                CreateAlarmAssistantIntent(
                    time: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
                    label: "Morning Wake Up",
                    repeatFrequency: .weekdays,
                    icon: "sunrise",
                    colorHex: "#FF6B6B",
                    soundName: "Gentle"
                ),
                CreateAlarmAssistantIntent(
                    time: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: today) ?? today,
                    label: "Early Wake Up",
                    repeatFrequency: .daily,
                    icon: "sun.max",
                    colorHex: "#FFEAA7",
                    soundName: "Chimes"
                )
            ]
            
        case "bedtime", "sleep":
            return [
                CreateAlarmAssistantIntent(
                    time: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today) ?? today,
                    label: "Bedtime",
                    repeatFrequency: .daily,
                    icon: "moon",
                    colorHex: "#4ECDC4",
                    soundName: "Nature"
                )
            ]
            
        case "exercise", "workout":
            return [
                CreateAlarmAssistantIntent(
                    time: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today) ?? today,
                    label: "Morning Exercise",
                    repeatFrequency: .weekdays,
                    icon: "figure.run",
                    colorHex: "#96CEB4",
                    soundName: "Bells"
                )
            ]
            
        default:
            return []
        }
    }
}
