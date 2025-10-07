//
//  figApp.swift
//  fig
//
//  Created by Mayank Gandhi on 04/10/25.
//

import SwiftUI
import SwiftData
import AlarmKit

@main
struct figApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AlarmItem.self,
            TemplateCategory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
            TemplateDataSeeder.seedTemplatesIfNeeded(modelContext: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(sharedModelContainer)
    }
}
