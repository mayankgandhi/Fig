//
//  TemplateCategory.swift
//  fig
//
//  SwiftData model for alarm template categories
//

import Foundation
import SwiftData

@Model
final class TemplateCategory {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var categoryDescription: String

    @Relationship(deleteRule: .cascade)
    var templates: [Ticker]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        description: String,
        templates: [Ticker] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.categoryDescription = description
        self.templates = templates
    }

    var templateCount: Int {
        templates.count
    }
}
