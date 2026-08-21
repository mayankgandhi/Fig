//
//  StopIntent.swift
//  fig
//
//  AppIntent for stopping an alarm
//

import AlarmKit
import AppIntents

/// An intent that stops an active alarm.
///
/// Used by the Live Activity and Dynamic Island presentations, and installed as
/// the configuration-level `stopIntent`.
///
/// This intent deliberately does **not** dismiss the Live Activity itself.
/// AlarmKit owns the Live Activity lifecycle for alarms it presents; ending the
/// activity by hand raced AlarmKit's own teardown. The previous implementation
/// also did that work in a detached `Task` after `perform()` returned, which a
/// `LiveActivityIntent` process is free to suspend before it ever runs.
@available(iOS 26.0, *)
public struct StopIntent: LiveActivityIntent {

    // `static let` rather than `static var`: a mutable static is shared mutable
    // state across the process and is not concurrency-safe.
    public static let title: LocalizedStringResource = "Stop"
    public static let description = IntentDescription("Stop an alert")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init() {
        self.alarmID = ""
    }

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public func perform() throws -> some IntentResult {
        // A malformed parameter must not crash the intent process while an alarm
        // is ringing — the user would lose the only control they have.
        guard let alarmUUID = UUID(uuidString: alarmID) else {
            print("⚠️ StopIntent: ignoring malformed alarmID '\(alarmID)'")
            return .result()
        }

        print("🛑 StopIntent.perform() for alarm \(alarmUUID)")

        do {
            try AlarmManager.shared.stop(id: alarmUUID)
            print("   ✅ Stopped alarm \(alarmUUID)")
            AlarmReactionRecorder.record(.stopped, alarmID: alarmUUID)
        } catch {
            // Nothing useful to surface from a Live Activity button, but the
            // failure must not be silent.
            print("   ❌ Failed to stop alarm \(alarmUUID): \(error)")
            AlarmReactionRecorder.record(.stopFailed, alarmID: alarmUUID)
        }

        return .result()
    }
}
