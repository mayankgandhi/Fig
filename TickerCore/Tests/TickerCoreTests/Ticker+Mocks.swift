//
//  Ticker+Mocks.swift
//  TickerCoreTests
//
//  Mock Ticker instances for testing various scenarios and edge cases
//

import Foundation
import TickerCore

extension Ticker {
    
    // MARK: - Basic Variations
    
    /// Basic daily ticker at 9:00 AM
    static var mockDailyMorning: Ticker {
        Ticker(
            label: "Morning Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Basic daily ticker at midnight
    static var mockDailyMidnight: Ticker {
        Ticker(
            label: "Midnight Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 0, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Basic daily ticker at 11:59 PM
    static var mockDailyEndOfDay: Ticker {
        Ticker(
            label: "End of Day Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 23, minute: 59)),
            presentation: .init()
        )
    }
    
    /// One-time ticker in the future
    static var mockOneTimeFuture: Ticker {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return Ticker(
            label: "Future Event",
            isEnabled: true,
            schedule: .oneTime(date: futureDate),
            presentation: .init()
        )
    }
    
    /// One-time ticker in the past
    static var mockOneTimePast: Ticker {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return Ticker(
            label: "Past Event",
            isEnabled: true,
            schedule: .oneTime(date: pastDate),
            presentation: .init()
        )
    }
    
    /// Hourly ticker (every 1 hour)
    static var mockHourly: Ticker {
        Ticker(
            label: "Hourly Reminder",
            isEnabled: true,
            schedule: .hourly(interval: 1, time: .init(hour: 0, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Every N hours ticker (every 3 hours)
    static var mockEveryThreeHours: Ticker {
        Ticker(
            label: "Every 3 Hours",
            isEnabled: true,
            schedule: .hourly(interval: 3, time: .init(hour: 8, minute: 30)),
            presentation: .init()
        )
    }
    
    /// Weekdays ticker (Monday to Friday)
    static var mockWeekdays: Ticker {
        Ticker(
            label: "Weekday Alarm",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 7, minute: 0),
                days: [.monday, .tuesday, .wednesday, .thursday, .friday]
            ),
            presentation: .init()
        )
    }
    
    /// Single weekday ticker (Sunday only)
    static var mockSingleWeekday: Ticker {
        Ticker(
            label: "Sunday Alarm",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 10, minute: 0),
                days: [.sunday]
            ),
            presentation: .init()
        )
    }
    
    /// Biweekly ticker
    static var mockBiweekly: Ticker {
        Ticker(
            label: "Biweekly Alarm",
            isEnabled: true,
            schedule: .biweekly(
                time: .init(hour: 14, minute: 30),
                weekdays: [.monday, .wednesday, .friday]
            ),
            presentation: .init()
        )
    }
    
    /// Monthly ticker (fixed day 15)
    static var mockMonthlyFixed: Ticker {
        Ticker(
            label: "Monthly Fixed",
            isEnabled: true,
            schedule: .monthly(
                day: .fixed(15),
                time: .init(hour: 12, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Monthly ticker (first Monday)
    static var mockMonthlyFirstWeekday: Ticker {
        Ticker(
            label: "Monthly First Monday",
            isEnabled: true,
            schedule: .monthly(
                day: .firstWeekday(.monday),
                time: .init(hour: 9, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Monthly ticker (last day of month)
    static var mockMonthlyLastDay: Ticker {
        Ticker(
            label: "Monthly Last Day",
            isEnabled: true,
            schedule: .monthly(
                day: .lastOfMonth,
                time: .init(hour: 18, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Yearly ticker
    static var mockYearly: Ticker {
        Ticker(
            label: "Anniversary",
            isEnabled: true,
            schedule: .yearly(
                month: 6,
                day: 15,
                time: .init(hour: 10, minute: 30)
            ),
            presentation: .init()
        )
    }
    
    /// Every N minutes ticker (high frequency)
    static var mockEveryFiveMinutes: Ticker {
        Ticker(
            label: "Every 5 Minutes",
            isEnabled: true,
            schedule: .every(
                interval: 5,
                unit: .minutes,
                time: .init(hour: 0, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Every N days ticker
    static var mockEveryThreeDays: Ticker {
        Ticker(
            label: "Every 3 Days",
            isEnabled: true,
            schedule: .every(
                interval: 3,
                unit: .days,
                time: .init(hour: 8, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    // MARK: - Edge Cases
    
    /// Ticker with empty label (edge case for displayName)
    static var mockEmptyLabel: Ticker {
        Ticker(
            label: "",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Disabled ticker
    static var mockDisabled: Ticker {
        Ticker(
            label: "Disabled Alarm",
            isEnabled: false,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Ticker with no schedule
    static var mockNoSchedule: Ticker {
        Ticker(
            label: "No Schedule",
            isEnabled: true,
            schedule: nil,
            presentation: .init()
        )
    }
    
    /// Ticker with countdown (preAlert only)
    static var mockWithPreAlert: Ticker {
        Ticker(
            label: "Pre-Alert Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 15, seconds: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with full countdown (preAlert and postAlert snooze)
    static var mockWithFullCountdown: Ticker {
        Ticker(
            label: "Full Countdown Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 30, seconds: 0),
                postAlert: .snooze(duration: .init(hours: 0, minutes: 10, seconds: 0))
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with countdown and repeat postAlert
    static var mockWithCountdownRepeat: Ticker {
        Ticker(
            label: "Repeat Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 1, minutes: 0, seconds: 0),
                postAlert: .repeat(duration: .init(hours: 0, minutes: 5, seconds: 0))
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with countdown and openApp postAlert
    static var mockWithCountdownOpenApp: Ticker {
        Ticker(
            label: "Open App Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 45, seconds: 0),
                postAlert: .openApp
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with custom sound
    static var mockWithCustomSound: Ticker {
        Ticker(
            label: "Custom Sound Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(),
            soundName: "custom_chime.mp3"
        )
    }
    
    /// Ticker with system default sound (nil soundName)
    static var mockWithDefaultSound: Ticker {
        Ticker(
            label: "Default Sound Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(),
            soundName: nil
        )
    }
    
    /// Ticker with tickerData
    static var mockWithTickerData: Ticker {
        Ticker(
            label: "Template Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(),
            tickerData: .init(
                name: "Workout",
                icon: "figure.run",
                colorHex: "#FF5733"
            )
        )
    }
    
    /// Ticker with presentation customization
    static var mockWithCustomPresentation: Ticker {
        Ticker(
            label: "Custom Presentation",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(
                tintColorHex: "#3498DB",
                secondaryButtonType: .countdown
            )
        )
    }
    
    /// Ticker with no secondary button
    static var mockWithNoSecondaryButton: Ticker {
        Ticker(
            label: "No Secondary Button",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(
                tintColorHex: nil,
                secondaryButtonType: .none
            )
        )
    }
    
    /// Ticker with high frequency regeneration strategy
    static var mockHighFrequencyStrategy: Ticker {
        Ticker(
            label: "High Frequency",
            isEnabled: true,
            schedule: .every(
                interval: 10,
                unit: .minutes,
                time: .init(hour: 0, minute: 0)
            ),
            presentation: .init(),
            regenerationStrategy: .highFrequency
        )
    }
    
    /// Ticker with medium frequency regeneration strategy
    static var mockMediumFrequencyStrategy: Ticker {
        Ticker(
            label: "Medium Frequency",
            isEnabled: true,
            schedule: .hourly(interval: 2, time: .init(hour: 0, minute: 0)),
            presentation: .init(),
            regenerationStrategy: .mediumFrequency
        )
    }
    
    /// Ticker with low frequency regeneration strategy
    static var mockLowFrequencyStrategy: Ticker {
        Ticker(
            label: "Low Frequency",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init(),
            regenerationStrategy: .lowFrequency
        )
    }
    
    /// Ticker with generated alarm IDs
    static var mockWithAlarmIDs: Ticker {
        let ticker = Ticker(
            label: "Generated Alarms",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
        ticker.generatedAlarmKitIDs = [UUID(), UUID(), UUID()]
        return ticker
    }
    
    /// Ticker with successful regeneration state
    static var mockRegenerationSuccess: Ticker {
        let ticker = Ticker(
            label: "Successfully Regenerated",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
        ticker.lastRegenerationDate = Date()
        ticker.lastRegenerationSuccess = true
        ticker.nextScheduledRegeneration = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        return ticker
    }
    
    /// Ticker with failed regeneration state
    static var mockRegenerationFailed: Ticker {
        let ticker = Ticker(
            label: "Failed Regeneration",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
        ticker.lastRegenerationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        ticker.lastRegenerationSuccess = false
        return ticker
    }
    
    /// Ticker that needs regeneration (stale)
    static var mockNeedsRegeneration: Ticker {
        let ticker = Ticker(
            label: "Needs Regeneration",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
        ticker.lastRegenerationDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        ticker.lastRegenerationSuccess = true
        return ticker
    }
    
    /// Ticker with scheduled regeneration time passed
    static var mockScheduledRegenerationPassed: Ticker {
        let ticker = Ticker(
            label: "Scheduled Regen Passed",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
        ticker.lastRegenerationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        ticker.lastRegenerationSuccess = true
        ticker.nextScheduledRegeneration = Calendar.current.date(byAdding: .hour, value: -1, to: Date())
        return ticker
    }
    
    /// Ticker that never regenerated
    static var mockNeverRegenerated: Ticker {
        Ticker(
            label: "Never Regenerated",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    // MARK: - Complex Combinations
    
    /// Complex ticker with all features
    static var mockComplex: Ticker {
        Ticker(
            label: "Complex Alarm",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 7, minute: 30),
                days: [.monday, .wednesday, .friday]
            ),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 20, seconds: 0),
                postAlert: .snooze(duration: .init(hours: 0, minutes: 10, seconds: 0))
            ),
            presentation: .init(
                tintColorHex: "#FF5733",
                secondaryButtonType: .countdown
            ),
            soundName: "custom_alarm.mp3",
            tickerData: .init(
                name: "Workout",
                icon: "figure.run",
                colorHex: "#FF5733"
            ),
            regenerationStrategy: .lowFrequency
        )
    }
    
    /// Ticker with extreme time values (12:00 PM)
    static var mockNoon: Ticker {
        Ticker(
            label: "Noon Alarm",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 12, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Ticker with all weekdays
    static var mockAllWeekdays: Ticker {
        Ticker(
            label: "Every Day",
            isEnabled: true,
            schedule: .weekdays(
                time: .init(hour: 8, minute: 0),
                days: TickerSchedule.Weekday.allCases
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with maximum interval (every 30 minutes)
    static var mockEveryThirtyMinutes: Ticker {
        Ticker(
            label: "Every 30 Minutes",
            isEnabled: true,
            schedule: .every(
                interval: 30,
                unit: .minutes,
                time: .init(hour: 0, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with minimum interval (every 1 minute - edge case)
    static var mockEveryMinute: Ticker {
        Ticker(
            label: "Every Minute",
            isEnabled: true,
            schedule: .every(
                interval: 1,
                unit: .minutes,
                time: .init(hour: 0, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with very long countdown (24 hours)
    static var mockLongCountdown: Ticker {
        Ticker(
            label: "Long Countdown",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 24, minutes: 0, seconds: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with zero countdown (edge case)
    static var mockZeroCountdown: Ticker {
        Ticker(
            label: "Zero Countdown",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            countdown: .init(
                preAlert: .init(hours: 0, minutes: 0, seconds: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with very long label (edge case)
    static var mockLongLabel: Ticker {
        Ticker(
            label: "This is a very long alarm label that might cause UI layout issues or truncation problems in the user interface",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Ticker with special characters in label
    static var mockSpecialCharactersLabel: Ticker {
        Ticker(
            label: "Alarm ⏰ with 🎉 emoji & symbols! @#$%",
            isEnabled: true,
            schedule: .daily(time: .init(hour: 9, minute: 0)),
            presentation: .init()
        )
    }
    
    /// Ticker with yearly schedule on leap year day (Feb 29)
    static var mockLeapYear: Ticker {
        Ticker(
            label: "Leap Year Alarm",
            isEnabled: true,
            schedule: .yearly(
                month: 2,
                day: 29,
                time: .init(hour: 12, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with monthly schedule on day 31 (edge case for months with fewer days)
    static var mockMonthlyDay31: Ticker {
        Ticker(
            label: "Monthly Day 31",
            isEnabled: true,
            schedule: .monthly(
                day: .fixed(31),
                time: .init(hour: 9, minute: 0)
            ),
            presentation: .init()
        )
    }
    
    /// Ticker with every N weeks schedule
    static var mockEveryTwoWeeks: Ticker {
        Ticker(
            label: "Every 2 Weeks",
            isEnabled: true,
            schedule: .every(
                interval: 2,
                unit: .weeks,
                time: .init(hour: 10, minute: 0)
            ),
            presentation: .init()
        )
    }
}

