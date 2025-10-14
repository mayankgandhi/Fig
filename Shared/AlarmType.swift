//
//  AlarmType.swift
//  fig
//
//  SwiftData model for custom alarm types with icons and names
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class AlarmType {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "alarm",
        colorHex: String = "#8B5CF6"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date.now
    }

}

extension AlarmType {
    
    var displayName: String {
        name.isEmpty ? "Alarm Type" : name
    }
    
    var color: Color {
        Color(hex: colorHex) ?? TickerColor.primary
    }
}
