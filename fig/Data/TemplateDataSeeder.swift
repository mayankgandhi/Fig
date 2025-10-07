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
            GeneralAlarm(
                label: "Morning Workout",
                schedule: .daily(time: .init(hour: 6, minute: 30))
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
            BillPaymentAlarm(
                label: "Pay Rent",
                accountName: "Rent",
                schedule: .monthly(time: .init(hour: 9, minute: 0), day: 1)
            ),
            CreditCardAlarm(
                label: "Credit Card Payment",
                cardName: "Credit Card",
                schedule: .monthly(time: .init(hour: 10, minute: 0), day: 15)
            ),
            BillPaymentAlarm(
                label: "Insurance Premium",
                accountName: "Insurance",
                schedule: .monthly(time: .init(hour: 9, minute: 0), day: 5)
            ),
            SubscriptionAlarm(
                label: "Netflix Subscription",
                serviceName: "Netflix",
                amount: 15.99,
                renewalDay: 10,
                schedule: .monthly(time: .init(hour: 8, minute: 0), day: 10)
            ),
            BillPaymentAlarm(
                label: "Utility Bills",
                accountName: "Utilities",
                schedule: .monthly(time: .init(hour: 10, minute: 0), day: 20)
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
            MedicationAlarm(
                label: "Morning Medication",
                medicationName: "Daily Vitamins",
                dosage: "1 tablet",
                schedule: .daily(time: .init(hour: 8, minute: 0))
            ),
            MedicationAlarm(
                label: "Evening Medication",
                medicationName: "Prescription",
                dosage: "As prescribed",
                schedule: .daily(time: .init(hour: 20, minute: 0))
            ),
            AppointmentAlarm(
                label: "Doctor Checkup",
                location: "Medical Center",
                schedule: .monthly(time: .init(hour: 14, minute: 0), day: 15)
            ),
            GeneralAlarm(
                label: "Drink Water",
                schedule: .daily(time: .init(hour: 12, minute: 0))
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
