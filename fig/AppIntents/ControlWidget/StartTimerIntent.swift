//
//  StartTimerIntent.swift
//  fig
//
//  AppIntent for starting a timer from control widget
//

import AppIntents

/// An intent that starts or stops a timer
///
/// This intent is used in the control widget to toggle the timer state.
/// It implements `SetValueIntent` to handle on/off toggle behavior.
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    /// The name of the timer to control
    @Parameter(title: "Timer Name")
    var name: String

    /// Whether the timer is currently running
    @Parameter(title: "Timer is running")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        // Start the timer…
        return .result()
    }
}
