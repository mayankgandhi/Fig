//
//  TimerConfiguration.swift
//  fig
//
//  Control widget configuration intent
//

import AppIntents

/// A configuration intent for the timer control widget
///
/// This intent allows users to configure the control widget with a custom timer name.
/// It's used by the control widget to provide configurable parameters.
struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    /// The name of the timer
    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}
