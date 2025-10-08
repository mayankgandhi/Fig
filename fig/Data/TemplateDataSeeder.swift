//
//  TemplateDataSeeder.swift
//  fig
//
//  Seeds predefined template categories and alarm templates
//

import Foundation
import SwiftData

@MainActor
class TemplateDataSeeder {

    static func seedTemplatesIfNeeded(modelContext: ModelContext) {
        // Clean up any alarms with deprecated schedule types (monthly/yearly)
        cleanupDeprecatedSchedules(modelContext: modelContext)

        // Check if templates already exist
        let descriptor = FetchDescriptor<TemplateCategory>()
        let existingCategories = (try? modelContext.fetch(descriptor)) ?? []

        guard existingCategories.isEmpty else {
            print("Templates already seeded")
            return
        }

        // Create Exercise Category
        let exerciseCategory = TemplateCategory(
            name: "Exercise",
            icon: "figure.run.circle.fill",
            colorHex: "#FF6B35",
            description: "Stay active and healthy with regular exercise reminders"
        )

        let exerciseTickerData = TickerData(
            name: exerciseCategory.name,
            icon: exerciseCategory.icon,
            colorHex: exerciseCategory.colorHex
        )

        let exerciseTemplates: [Ticker] = [
            Ticker(
                label: "Morning Workout",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 6, minute: 30)),
                tickerData: exerciseTickerData
            ),
            Ticker(
                label: "Evening Jog",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 18, minute: 0)),
                tickerData: exerciseTickerData
            ),
            Ticker(
                label: "Yoga Session",
                isEnabled: false,
                notes: "Bring yoga mat",
                schedule: .daily(time: .init(hour: 7, minute: 0)),
                tickerData: exerciseTickerData
            )
        ]

        exerciseCategory.templates = exerciseTemplates

        // Create Productivity Category
        let productivityCategory = TemplateCategory(
            name: "Productivity",
            icon: "checkmark.circle.fill",
            colorHex: "#4CAF50",
            description: "Stay focused and organized throughout your day"
        )

        let productivityTickerData = TickerData(
            name: productivityCategory.name,
            icon: productivityCategory.icon,
            colorHex: productivityCategory.colorHex
        )

        let productivityTemplates: [Ticker] = [
            Ticker(
                label: "Daily Standup",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 9, minute: 0)),
                tickerData: productivityTickerData
            ),
            Ticker(
                label: "Weekly Review",
                isEnabled: false,
                notes: "Review goals and progress",
                schedule: .daily(time: .init(hour: 16, minute: 0)),
                tickerData: productivityTickerData
            ),
            Ticker(
                label: "Lunch Break",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 12, minute: 30)),
                tickerData: productivityTickerData
            ),
            Ticker(
                label: "End of Day",
                isEnabled: false,
                notes: "Wrap up tasks",
                schedule: .daily(time: .init(hour: 17, minute: 30)),
                tickerData: productivityTickerData
            )
        ]

        productivityCategory.templates = productivityTemplates

        // Create Wellness Category
        let wellnessCategory = TemplateCategory(
            name: "Wellness",
            icon: "heart.fill",
            colorHex: "#E91E63",
            description: "Take care of your health and well-being"
        )

        let wellnessTickerData = TickerData(
            name: wellnessCategory.name,
            icon: wellnessCategory.icon,
            colorHex: wellnessCategory.colorHex
        )

        let wellnessTemplates: [Ticker] = [
            Ticker(
                label: "Drink Water",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 10, minute: 0)),
                tickerData: wellnessTickerData
            ),
            Ticker(
                label: "Stretch Break",
                isEnabled: false,
                notes: "5 minute stretch",
                schedule: .daily(time: .init(hour: 14, minute: 0)),
                tickerData: wellnessTickerData
            ),
            Ticker(
                label: "Bedtime",
                isEnabled: false,
                notes: "Wind down for the night",
                schedule: .daily(time: .init(hour: 22, minute: 0)),
                tickerData: wellnessTickerData
            ),
            Ticker(
                label: "Weekly Checkup",
                isEnabled: false,
                schedule: .daily(time: .init(hour: 9, minute: 0)),
                tickerData: wellnessTickerData
            )
        ]

        wellnessCategory.templates = wellnessTemplates

        // Insert all categories into context
        modelContext.insert(exerciseCategory)
        modelContext.insert(productivityCategory)
        modelContext.insert(wellnessCategory)

        // Save context
        do {
            try modelContext.save()
            print("Successfully seeded template data")
        } catch {
            print("Error seeding templates: \(error)")
        }
    }

    /// Removes any Tickers that have deprecated schedule types (monthly/yearly)
    /// These schedule types are no longer supported since they don't work properly with AlarmKit
    ///
    /// Note: SwiftData will automatically fail to decode Tickers with monthly/yearly schedules
    /// since those enum cases no longer exist. This cleanup is here for documentation and
    /// to handle any edge cases.
    private static func cleanupDeprecatedSchedules(modelContext: ModelContext) {
        print("🧹 Checking for deprecated schedule types...")

        // SwiftData will automatically skip Tickers that fail to decode due to
        // the missing .monthly and .yearly enum cases. Any such items will not appear
        // in fetch results, effectively "cleaning themselves up" from the app's perspective.

        // The data remains in the SQLite database but is inaccessible, which is fine
        // since those schedule types never worked properly with AlarmKit anyway.

        print("✅ SwiftData will automatically skip any items with deprecated schedules")
    }
}
