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
            icon: "figure.run",
            colorHex: "#FF6B35",
            description: "Stay active and healthy with regular exercise reminders"
        )

        let exerciseTemplates: [AlarmItem] = [
            AlarmItem(
                label: "Morning Workout",
                schedule: .daily(time: .init(hour: 6, minute: 30))
            ),
            AlarmItem(
                label: "Evening Jog",
                schedule: .daily(time: .init(hour: 18, minute: 0))
            ),
            AlarmItem(
                label: "Yoga Session",
                notes: "Bring yoga mat",
                schedule: .daily(time: .init(hour: 7, minute: 0))
            )
        ]

        exerciseCategory.templates = exerciseTemplates

        // Create Productivity Category
        let productivityCategory = TemplateCategory(
            name: "Productivity",
            icon: "checkmark.circle",
            colorHex: "#4CAF50",
            description: "Stay focused and organized throughout your day"
        )

        let productivityTemplates: [AlarmItem] = [
            AlarmItem(
                label: "Daily Standup",
                schedule: .daily(time: .init(hour: 9, minute: 0))
            ),
            AlarmItem(
                label: "Weekly Review",
                notes: "Review goals and progress",
                schedule: .monthly(time: .init(hour: 16, minute: 0), day: 1)
            ),
            AlarmItem(
                label: "Lunch Break",
                schedule: .daily(time: .init(hour: 12, minute: 30))
            ),
            AlarmItem(
                label: "End of Day",
                notes: "Wrap up tasks",
                schedule: .daily(time: .init(hour: 17, minute: 30))
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

        let wellnessTemplates: [AlarmItem] = [
            AlarmItem(
                label: "Drink Water",
                schedule: .daily(time: .init(hour: 10, minute: 0))
            ),
            AlarmItem(
                label: "Stretch Break",
                notes: "5 minute stretch",
                schedule: .daily(time: .init(hour: 14, minute: 0))
            ),
            AlarmItem(
                label: "Bedtime",
                notes: "Wind down for the night",
                schedule: .daily(time: .init(hour: 22, minute: 0))
            ),
            AlarmItem(
                label: "Weekly Checkup",
                schedule: .monthly(time: .init(hour: 9, minute: 0), day: 7)
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
}
