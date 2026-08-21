# Changelog

All notable changes to Ticker are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.4] - 2026-08-21

The alarms release. Ticker's one promise is that it wakes you up, and for the
most common alarm in the product — "weekdays at 7am" — it was not reliably
keeping it. This release fixes that, stops the app deleting alarms you created,
and makes whether alarms actually fire something that can be measured instead
of guessed at.

### Fixed

- **A one-time alarm no longer disappears after it rings.** Reconciliation was
  deleting any enabled alarm it found with nothing scheduled, which described a
  perfectly normal alarm that had just gone off. Spent alarms are now switched
  off and kept in your list, the way the system Clock app does it.
- **Weekday alarms keep working indefinitely.** "Mon–Fri at 7am" was being
  broken up into a handful of individual one-off alarms that had to be topped up
  by a background task which never actually ran. Once the batch ran out — within
  a week — the alarm stopped, silently. Weekday alarms now use a single repeating
  alarm that does not need topping up.
- **Alarms no longer stop being created once you have a lot of them.** There was
  no limit on how many alarms could be scheduled at once, so a few frequent
  reminders could quietly exhaust the system budget and every alarm created after
  that failed with nothing shown. Scheduling now stays within a fixed budget.
- **A failed alarm never takes your alarm with it.** If scheduling failed, the
  recovery path deleted the alarm it was trying to save — and because alarms in a
  collection are linked, it could take the whole collection. Recovery is now
  limited to alarms the failed attempt itself created.
- **Snooze and Stop work from the Dynamic Island and lock screen.** The alarm's
  Live Activity showed nothing at all while ringing, and Snooze was unreachable
  from every surface. Both buttons are now present, Snooze is the larger target,
  and the alarm time is the first thing you see.
- **The countdown ring moves.** It was frozen at its starting position for the
  whole countdown.
- **Tapping Open on a ringing alarm stops it.** It previously opened the app and
  left the alarm ringing.
- **Alarms no longer shift when you travel.** The widget and the alarm itself
  could disagree about the time after a timezone change.
- **The Dynamic Island is readable.** Alarm colours were being drawn dark on the
  Island's black background, and an alarm with no colour set rendered invisible.
- **"Remind me in 2 hours" late at night now lands tomorrow.** Between 22:00 and
  midnight it was resolving to earlier the same day, putting the reminder in the
  past.
- Stop, Snooze, Repeat and Open no longer crash the alarm's button process on
  malformed input, and no longer race the system over dismissing the alarm.

### Added

- Alarm reliability is now measured. The app records whether alarms actually
  fired, how many were expected, and how you responded, so a failure of the
  alarm pipeline is visible instead of waiting on a bug report.
- Existing weekday alarms are upgraded automatically on first launch, and the
  upgrade verifies each old alarm is really gone before arming its replacement,
  so you never get two alerts the same morning. A repeating alarm also can no
  longer be pulled back onto the old top-up path, which was the other way the
  same double-alert could have happened.
- The lock-screen alarm banner scales with your Larger Text setting.
- Live Activity controls are labelled for VoiceOver and meet the recommended
  touch-target size.

### Changed

- Alarm storage now has a single versioned schema shared by the app, the widget
  and the alarm buttons. They previously each described the store differently,
  which risked an unrecoverable crash on launch after an update — the kind whose
  only fix is deleting the app, taking every alarm with it. A failure opening
  storage is now reported rather than fatal.
- Alarm code is compiled with strict concurrency checking, which surfaced and
  fixed data races around alarm reads and writes.

### Internal

- Alarm scheduling now sits behind a seam that can be substituted in tests, so
  the failure paths that caused these bugs are reachable from the test suite for
  the first time. Test count went from 246 to 293, and several existing tests
  that asserted the old delete-the-alarm behaviour were rewritten to assert the
  opposite.
- The fire measurement itself is kept honest: an alarm you cancel or edit is not
  counted as having rung, and a fire that happened before the weekday upgrade is
  counted before the upgrade clears its record.
- `PLAN-alarm-reliability.md` records the investigation, the verified root
  causes, and what was deliberately deferred.
