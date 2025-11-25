//
//  SleepScheduleViewModel.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import SwiftData
import TickerCore
import Factory

@Observable
@MainActor
final class SleepScheduleViewModel {

    // MARK: - Properties

    var bedtime: TimeOfDay
    var wakeTime: TimeOfDay
    var label: String = "Sleep Schedule"

    // Presentation
    var presentation: TickerPresentation

    // Edit mode
    var compositeTickerToUpdate: CompositeTicker?

    // UI State
    var isCreating: Bool = false
    var error: Error?
    var showingError: Bool = false

    // Services
    @ObservationIgnored
    @Injected(\.compositeTickerService) private var compositeService

    // MARK: - Initialization

    init(
        bedtime: TimeOfDay = TimeOfDay(hour: 22, minute: 0), // 10:00 PM default
        wakeTime: TimeOfDay = TimeOfDay(hour: 6, minute: 30), // 6:30 AM default
        presentation: TickerPresentation = TickerPresentation(),
        compositeTickerToUpdate: CompositeTicker? = nil
    ) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.presentation = presentation
        self.compositeTickerToUpdate = compositeTickerToUpdate
        if let composite = compositeTickerToUpdate {
            self.label = composite.label
        }
    }

    // MARK: - Computed Properties

    /// Sleep duration in hours
    var sleepDuration: Double {
        let config = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime
        )
        return config.sleepDuration
    }

    /// Formatted sleep duration (e.g., "7 hr 25 min")
    var formattedDuration: String {
        let config = SleepScheduleConfiguration(
            bedtime: bedtime,
            wakeTime: wakeTime
        )
        return config.formattedDuration
    }

    // MARK: - Actions

    /// Create or update the sleep schedule composite ticker
    func createSleepSchedule(modelContext: ModelContext) async throws {
        guard !isCreating else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            if let composite = compositeTickerToUpdate {
                // Update existing sleep schedule
                try await compositeService.updateSleepSchedule(
                    composite,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    modelContext: modelContext
                )
            } else {
                // Create new sleep schedule
                _ = try await compositeService.createSleepSchedule(
                    label: label,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    presentation: presentation,
                    modelContext: modelContext
                )
            }
        } catch {
            self.error = error
            self.showingError = true
            throw error
        }
    }

    /// Update bedtime by dragging
    func updateBedtime(to time: TimeOfDay) {
        bedtime = time
    }

    /// Update wake time by dragging
    func updateWakeTime(to time: TimeOfDay) {
        wakeTime = time
    }

    /// Convert angle to TimeOfDay (0° = midnight at top, clockwise)
    func angleToTime(_ angle: Angle) -> TimeOfDay {
        // Normalize angle to 0-360 range
        var normalizedDegrees = angle.degrees.truncatingRemainder(dividingBy: 360)
        if normalizedDegrees < 0 {
            normalizedDegrees += 360
        }

        // Convert to hours (0° = 0:00, 90° = 6:00, 180° = 12:00, 270° = 18:00)
        let totalMinutes = Int((normalizedDegrees / 360.0) * (24 * 60))
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        // Round to nearest 5 minutes for better UX
        let roundedMinutes = (minutes / 5) * 5

        return TimeOfDay(hour: hours, minute: roundedMinutes)
    }

    /// Convert TimeOfDay to angle (0° = midnight at top, clockwise)
    func timeToAngle(_ time: TimeOfDay) -> Angle {
        let totalMinutes = time.hour * 60 + time.minute
        let degrees = (Double(totalMinutes) / (24 * 60)) * 360
        return Angle(degrees: degrees)
    }
}
