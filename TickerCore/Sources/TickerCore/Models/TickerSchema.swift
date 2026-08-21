//
//  TickerSchema.swift
//  TickerCore
//
//  The single source of truth for the SwiftData schema and the shared
//  App Group store.
//
//  Before this existed, four sites built their own `Schema(...)` over the same
//  file in `group.m.fig`:
//
//    figApp.swift            Schema([Ticker.self, TickerCollection.self])
//    StopIntent.swift        Schema([Ticker.self])
//    OpenAlarmAppIntent.swift Schema([Ticker.self])
//    WidgetDataFetcher.swift Schema([Ticker.self])
//
//  Three processes (app, widget extension, intent extension) opening one store
//  under disagreeing model sets is a migration hazard: whichever process opens
//  the store first after an update decides how it migrates, and the widget can
//  easily win that race because WidgetKit reloads timelines on install.
//  `TickerCollection` also owns a `.cascade` relationship whose inverse lives on
//  `Ticker`, so the narrower set is not obviously safe to use.
//
//  Everything now goes through `TickerSchema`.
//

import Foundation
import SwiftData

// MARK: - Versioned Schema

/// Version 1 of the Ticker store.
///
/// Introduced when the schema was unified. It deliberately describes the shape
/// the app already shipped, so adopting `VersionedSchema` is a no-op migration —
/// the machinery is in place before the first real change needs it.
public enum TickerSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [Ticker.self, TickerCollection.self]
    }
}

/// Migration plan for the Ticker store.
///
/// When a new version is added, append it to `schemas` and add the corresponding
/// `MigrationStage` here. Additive optional attributes migrate lightweight.
public enum TickerMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [TickerSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Store Access

public enum TickerSchema {

    /// App Group shared between the app, the widget extension and the intents.
    public static let appGroupIdentifier = "group.m.fig"

    /// File name of the SwiftData store inside the App Group container.
    public static let storeFileName = "Ticker.sqlite"

    /// The current schema. Every process must use this and only this.
    public static var current: Schema {
        Schema(versionedSchema: TickerSchemaV1.self)
    }

    /// Configuration pointing at the shared App Group store, falling back to a
    /// process-local store when the container is unavailable (for example in
    /// tests or previews where the entitlement is absent).
    public static func makeConfiguration() -> ModelConfiguration {
        if let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return ModelConfiguration(
                schema: current,
                url: sharedURL.appendingPathComponent(storeFileName)
            )
        }
        return ModelConfiguration(schema: current, isStoredInMemoryOnly: false)
    }

    /// Builds the shared container.
    ///
    /// Throws rather than trapping. Callers in extension processes must degrade
    /// gracefully: a `fatalError` here crashes the intent process while an alarm
    /// is ringing, and in the app it produces a launch crash loop whose only
    /// remedy is deleting the app — taking every alarm with it.
    public static func makeSharedContainer() throws -> ModelContainer {
        try ModelContainer(
            for: current,
            migrationPlan: TickerMigrationPlan.self,
            configurations: [makeConfiguration()]
        )
    }

    /// Convenience for extension processes that just need a context.
    /// Returns `nil` instead of trapping when the store cannot be opened.
    public static func makeSharedContext() -> ModelContext? {
        guard let container = try? makeSharedContainer() else {
            print("⚠️ TickerSchema: could not open the shared store")
            return nil
        }
        return ModelContext(container)
    }
}
