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
                label: "Physical Therapy",
                category: .appointment(location: "Physio Clinic"),
                schedule: .weekly(
                    time: .init(hour: 10, minute: 0),
                    weekdays: [.monday, .wednesday, .friday]
                ),
            ),
            AlarmItem(
                label: "Morning Workout",
                category: .general(),
                schedule: .daily(time: .init(hour: 6, minute: 30)),
            ),
            AlarmItem(
                label: "Yoga Session",
                category: .general(),
                schedule: .weekly(
                    time: .init(hour: 18, minute: 0),
                    weekdays: [.tuesday, .thursday, .saturday]
                ),
            ),
            AlarmItem(
                label: "Weekend Run",
                category: .general(),
                schedule: .weekly(
                    time: .init(hour: 7, minute: 0),
                    weekdays: [.saturday, .sunday]
                ),
            )
        ]

        exerciseCategory.templates = exerciseTemplates

        // Create Finances Category
        let financesCategory = TemplateCategory(
            name: "Finances",
            icon: "dollarsign.circle",
            colorHex: "#4CAF50",
            description: "Never miss a payment with timely financial reminders"
        )

        let financesTemplates: [AlarmItem] = [
            AlarmItem(
                label: "Pay Rent",
                category: .billPayment(accountName: "Rent"),
                schedule: .monthly(time: .init(hour: 9, minute: 0), day: 1),
            ),
            AlarmItem(
                label: "Credit Card Payment",
                category: .creditCard(cardName: "Credit Card"),
                schedule: .monthly(time: .init(hour: 10, minute: 0), day: 15),
            ),
            AlarmItem(
                label: "Insurance Premium",
                category: .billPayment(accountName: "Insurance"),
                schedule: .monthly(time: .init(hour: 9, minute: 0), day: 5),
            ),
            AlarmItem(
                label: "Netflix Subscription",
                category: .subscription(serviceName: "Netflix", amount: 15.99, renewalDay: 10),
                schedule: .monthly(time: .init(hour: 8, minute: 0), day: 10),
            ),
            AlarmItem(
                label: "Utility Bills",
                category: .billPayment(accountName: "Utilities"),
                schedule: .monthly(time: .init(hour: 10, minute: 0), day: 20),
            )
        ]

        financesCategory.templates = financesTemplates

        // Create Health Category
        let healthCategory = TemplateCategory(
            name: "Health",
            icon: "heart.fill",
            colorHex: "#E91E63",
            description: "Stay on top of your health with medication and checkup reminders"
        )

        let healthTemplates: [AlarmItem] = [
            AlarmItem(
                label: "Morning Medication",
                category: .medication(medicationName: "Daily Vitamins", dosage: "1 tablet"),
                schedule: .daily(time: .init(hour: 8, minute: 0)),
            ),
            AlarmItem(
                label: "Evening Medication",
                category: .medication(medicationName: "Prescription", dosage: "As prescribed"),
                schedule: .daily(time: .init(hour: 20, minute: 0)),
            ),
            AlarmItem(
                label: "Weekly Injection",
                category: .medication(medicationName: "Weekly Shot", dosage: "1 dose"),
                schedule: .weekly(
                    time: .init(hour: 19, minute: 0),
                    weekdays: [.sunday]
                ),
            ),
            AlarmItem(
                label: "Doctor Checkup",
                category: .appointment(location: "Medical Center"),
                schedule: .monthly(time: .init(hour: 14, minute: 0), day: 15),
            ),
            AlarmItem(
                label: "Drink Water",
                category: .general(),
                schedule: .daily(time: .init(hour: 12, minute: 0)),
            ),
            AlarmItem(
                label: "Blood Pressure Check",
                category: .general(),
                schedule: .weekly(
                    time: .init(hour: 9, minute: 0),
                    weekdays: [.monday, .thursday]
                ),
            )
        ]

        healthCategory.templates = healthTemplates

        // Insert all categories into context
        modelContext.insert(exerciseCategory)
        modelContext.insert(financesCategory)
        modelContext.insert(healthCategory)

        // Save context
        do {
            try modelContext.save()
            print("Successfully seeded template data")
        } catch {
            print("Error seeding templates: \(error)")
        }
    }
}
