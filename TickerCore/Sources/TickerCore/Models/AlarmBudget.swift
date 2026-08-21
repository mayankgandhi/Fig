//
//  AlarmBudget.swift
//  TickerCore
//
//  Global accounting for how many alarms may be armed in AlarmKit at once.
//
//  AlarmKit enforces a per-app limit and reports it as
//  `AlarmManager.AlarmError.maximumLimitReached`. Nothing in this app handled
//  that error, and nothing counted alarms globally: `AlarmGenerationStrategy`
//  capped only `.highFrequency` (at 100) and left `.mediumFrequency` and
//  `.lowFrequency` unlimited. Five hourly tickers alone project ~240 alarms over
//  a 48-hour window.
//
//  Once the limit is hit every subsequent `schedule()` throws, and because the
//  throw was swallowed or handled destructively, alarms simply stopped being
//  armed — with no error surfaced anywhere. That is the most likely mechanism
//  behind "it worked, then it stopped".
//

import Foundation

public enum AlarmBudget {

    /// Ceiling on alarms armed across every ticker.
    ///
    /// Deliberately conservative: the point is to stay clear of AlarmKit's own
    /// limit so that hitting it is our decision, made with a message we can show
    /// the user, rather than an opaque throw deep inside a transaction.
    public static let maxScheduledAlarms = 64

    /// Ceiling for a single ticker, so one high-frequency schedule cannot
    /// consume the whole budget and starve every other alarm.
    ///
    /// Sized against the widest generation window: `.mediumFrequency` expands 48
    /// hours ahead and regenerates once fewer than 24 hours remain, so 32 hourly
    /// occurrences keep an hourly ticker continuously covered while still leaving
    /// room for other alarms.
    public static let maxAlarmsPerTicker = 32

    /// How many alarms a ticker may add, given what is already armed.
    /// - Parameters:
    ///   - currentGlobalCount: alarms currently armed across all tickers
    ///   - currentTickerCount: alarms currently armed for this ticker
    /// - Returns: the number of new alarms that fit, never negative
    public static func allowance(
        currentGlobalCount: Int,
        currentTickerCount: Int
    ) -> Int {
        let globalRoom = max(0, maxScheduledAlarms - currentGlobalCount)
        let tickerRoom = max(0, maxAlarmsPerTicker - currentTickerCount)
        return min(globalRoom, tickerRoom)
    }
}
