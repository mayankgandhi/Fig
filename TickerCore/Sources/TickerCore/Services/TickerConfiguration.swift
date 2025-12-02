//
//  TickerConfiguration.swift
//  Ticker
//
//  Created by Mayank Gandhi on 27/10/25.
//

import Foundation
import FoundationModels

public struct TickerConfiguration: Codable, Equatable {
    public let label: String
    public let time: TimeOfDay
    public let date: Date
    public let repeatOption: AITickerGenerator.RepeatOption
    public let countdown: CountdownConfiguration?
    public let icon: String
    public let colorHex: String

    public struct CountdownConfiguration: Codable, Equatable {
        public let hours: Int
        public let minutes: Int
        public let seconds: Int
        
        public init(hours: Int, minutes: Int, seconds: Int) {
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }
    }
    
    public init(
        label: String,
        time: TimeOfDay,
        date: Date,
        repeatOption: AITickerGenerator.RepeatOption,
        countdown: CountdownConfiguration?,
        icon: String,
        colorHex: String
    ) {
        self.label = label
        self.time = time
        self.date = date
        self.repeatOption = repeatOption
        self.countdown = countdown
        self.icon = icon
        self.colorHex = colorHex
    }
}
