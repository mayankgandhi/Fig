//
//  AlarmEntity.swift
//  fig
//
//  Entity representing a ticker for Siri queries and parameter resolution
//

import Foundation
import AppIntents

/// Entity representing a ticker alarm for Siri queries
struct AlarmEntity: AppEntity {
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Ticker"
    static var defaultQuery = AlarmQuery()
    
    var id: UUID
    var displayRepresentation: DisplayRepresentation
    
    init(id: UUID, name: String) {
        self.id = id
        self.displayRepresentation = DisplayRepresentation(title: "\(name)")
    }
}

/// Query for finding existing tickers
struct AlarmQuery: EntityQuery {
    
    func entities(for identifiers: [UUID]) async throws -> [AlarmEntity] {
        // This would typically fetch from SwiftData, but for now return empty
        // In a full implementation, you'd query the shared ModelContainer
        return []
    }
    
    func entities(matching string: String) async throws -> [AlarmEntity] {
        // This would search tickers by name
        // For now, return empty array
        return []
    }
    
    func suggestedEntities() async throws -> [AlarmEntity] {
        // Return recently created or frequently used tickers
        return []
    }
}
