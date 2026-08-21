<!-- /autoplan restore point: /Users/mayankgandhi/.gstack/projects/mayankgandhi-Fig/main-autoplan-restore-20260810-053424.md -->

# Plan: Alarm reliability — "rings once and stops, no Dynamic Island"

**Branch:** main | **Commit at plan time:** 5ea8e4d
**Reviewed by:** /autoplan — CEO → Design → Eng, `[subagent-only]`
(Codex unavailable: the binary SIGKILLs on this machine, with and without sandbox)
**Test plan artifact:** `~/.gstack/projects/mayankgandhi-Fig/mayankgandhi-main-test-plan-20260810-053424.md`

Every claim below was verified against the source or the iOS 26.5 SDK interface at
`iPhoneOS26.5.sdk/.../AlarmKit.framework/Modules/AlarmKit.swiftmodule/arm64e-apple-ios.swiftinterface`.
Unverified claims are labelled HYPOTHESIS and are not treated as root causes.

---

## The report is two separate symptoms with different causes

Review established that these do not share a root cause, and conflating them sent
the first draft of this plan down the wrong path.

**"No Dynamic Island / no notification"** → the Live Activity renders `EmptyView()`
in the alerting state (RC1). Possibly compounded by a missing Info.plist key (H1).

**"Rings once and stops"** → the alarm fires correctly once, and then the *next*
occurrence never exists:
- one-time alarms: reconciliation **deletes the user's Ticker** after it fires (RC4)
- Mon–Fri alarms: they ride an expansion pipeline that never re-runs (RC0 + RC3 + RC5)
- any alarm: once the AlarmKit budget is exhausted, every subsequent `schedule()`
  throws and the throw is swallowed or destructive (RC7 + F5)

Fixing the Live Activity has **zero effect** on the ringing. Design and Eng flagged
this independently. AlarmKit presents its own full-screen system alert from
`AlarmPresentation.Alert`; the `ActivityConfiguration` in this repo governs the
Dynamic Island and the lock-screen banner, not whether the alarm rings.

---

## Root causes

### RC0 — `.weekdays` is natively expressible and isn't used (VERIFIED)

SDK interface line 170-171:
```swift
public enum Recurrence: Codable, Equatable, Sendable, Hashable {
  case weekly([Foundation.Locale.Weekday])
  case never
}
```

`weekly` takes an arbitrary weekday set. The app already builds this for `.daily`
(`Ticker.swift:341-349`, passing all seven days) but routes `.weekdays` to
`default: return nil` (`Ticker.swift:352-356`).

So "wake me Mon–Fri at 7am" is shredded into disposable one-time alarms and made
dependent on the regeneration + background-task + sync-deletion machinery. RC3, RC4
and RC5 are largely symptoms of that one routing decision.

### RC1 — Live Activity draws `EmptyView()` when alerting (VERIFIED)

`AlarmLiveActivity.swift` gates every surface on
`hasCountdownCapability(presentation) && hasCountdownState(state.mode)`.
`hasCountdownCapability` (37-40) needs `presentation.countdown != nil`;
`hasCountdownState` (44-53) returns `false` for `.alert`.
Applied at lines 62, 74, 97, 115, 215.

A plain alarm has no countdown, so it renders empty in **every** mode.

### RC2 — Presentation and countdown-duration gates disagree (VERIFIED)

| Function | Gate |
|---|---|
| `AlarmConfigurationBuilder.buildPresentation:98` | `countdown != nil` |
| `Ticker.alarmKitCountdownDuration:320` | `countdown.preAlert != nil` |

A Ticker with `countdown != nil, preAlert == nil` sends a countdown *presentation*
with a nil countdown *duration*. With the Repeat button selected, that pairs
`secondaryButtonBehavior == .countdown` with nothing to count.

The earlier claim that `postAlert` "governs the alerting window" was **wrong** and
is removed. `postAlert` is the repeat/snooze delay after the alert; ring duration is
system-controlled. The same misconception sits in a code comment at
`Ticker.swift:159` and should be corrected there.

### RC3 — Background regeneration is never scheduled (VERIFIED)

`scheduleBackgroundTask()` (`figApp.swift:209`) is called from exactly one place:
line 193, **inside** `handleBackgroundTask()`. Nothing submits the first request, so
the task never fires, so it never reschedules itself. `UIBackgroundModes` is also
absent from the Info.plist.

No foreground fallback exists. `AlarmRegenerationService.swift:17` documents
`case appForeground // PRIMARY - guaranteed` and nothing constructs it.
`AppView.swift:54-59` only re-checks permissions; `figApp.swift:131-133` only fires
an analytics event.

### RC4 — Reconciliation deletes the user's alarm after it fires (VERIFIED)

`AlarmSynchronizationService.swift:158-265` deletes any enabled Ticker with no live
AlarmKit alarm and no upcoming occurrence. A fired one-time alarm matches all three
conditions and is destroyed.

**The app silently deletes user-created data.** This is the most damaging defect
here and the direct cause of "it rings once and then it's gone."

Two existing tests assert this behavior is correct
(`AlarmSynchronizationServiceOrphanedTickersTests.swift:97`,
`AlarmSynchronizationServiceScheduleTypeTests.swift:52`). They must be rewritten.

### RC5 — Regeneration window origin frozen in the past (VERIFIED)

`calculateTargetDates:180-186` expands from `lastRegenerationDate ?? Date()`. After
the first pass that value is always past and is reused forever as the origin.

### RC6 — No way to know whether alarms fire (VERIFIED)

`AnalyticsEvents.swift` defines ~158 event symbols wired to PostHog. There is **no
alarm-fired event**. Measured: `.track()` calls in `TickerCore/Sources`: **0**.
`print()` calls in `TickerCore/Sources/TickerCore/Services`: **251**.

The business can measure paywall views to three decimals and cannot answer "did
alarms ring last night?" This bug class is structurally undetectable; it surfaced
because one user complained.

### RC7 — `maximumLimitReached` unhandled, and its failure path is destructive (VERIFIED)

SDK line 236-237: `public enum AlarmError: Swift.Error { case maximumLimitReached }`.
`grep` across all three targets returns nothing.

`AlarmGenerationStrategy.swift:35-43` caps only `.highFrequency` at 100;
`.mediumFrequency` and `.lowFrequency` set `maxAlarms = nil` (unlimited). Nothing
ever inspects `AlarmManager.alarms.count` globally. Five hourly tickers alone
project ~240 alarms.

Worse, the failure path destroys data (see F5 below). **This is the best available
explanation for "it worked, then stopped."**

### H1 — `NSSupportsLiveActivities` absent (HYPOTHESIS, not a root cause)

Genuinely absent — confirmed in `Project.swift:22-31` and the generated
`Derived/InfoPlists/Ticker-Info.plist`. ActivityKit documents it as required.

Causation is **not** established. Counter-evidence: an April 2026 project learning
tagged `source: "observed"` describes an animation failing to restart *inside* the
countdown Live Activity, which is hard to observe if the activity never starts.

Add the key — two lines, zero risk — but settle causation with a device experiment
before building on the assumption.

---

## Additional defects found in review

| # | File:line | Defect | Sev |
|---|---|---|---|
| F5 | `AlarmRegenerationService.swift:217-254` | Rollback is **not** atomic: `toDelete` is cancelled first; the catch only cancels newly-created alarms. Deleted alarms are gone permanently. The throw then reaches `TickerService.scheduleCollectionAlarm:278-292`, which **fetches the Ticker by ID and `context.delete`s it** — and `parentTickerCollection` is a `.cascade` inverse, so one deletion can take a collection with it. Same shape at `scheduleSimpleAlarm:220-235` | CRITICAL |
| F9 | `AlarmConfigurationBuilder.swift:117-128` | `buildSecondaryIntent` passes `alarmItem.id` (the SwiftData Ticker ID), but every scheduling site uses a fresh `UUID()` (`TickerService.swift:169`, `:364`, `AlarmRegenerationService.swift:226`). So `stop(id:)`/`countdown(id:)` are called with an ID that does not exist in AlarmKit and throw. `.openApp` is the **default** of `TickerPresentation.init` (`Ticker.swift:297`) — so for any older row, tapping "Open" throws, the alarm is not stopped, and the app opens anyway | CRITICAL |
| F1 | P0 as originally written | `alarmUpdates` is an **in-process** AsyncSequence. Nothing launches the app when an alarm fires. The `.alerting` transition is unobservable for the exact population being measured. Also yields full snapshots, not deltas | CRITICAL |
| F2 | P2 migration | After P2, `isSimpleSchedule(.weekdays) == true`, so `shouldRegenerate` goes false — but nothing reschedules existing tickers. Their old expansion runs out (≤7 days) and **the alarm stops forever, silently**. Schedule-before-cancel or a swallowed `try?` cancel gives a **double alert** the same morning | CRITICAL |
| F3 | P2 mapping | `days.map(\.localeWeekday)` is wrong when a pre-alert crosses midnight: `.weekdays(00:30,[.monday])` + 60min pre-alert must become `.weekly([.sunday])` @ 23:30, not `.weekly([.monday])` | CRITICAL |
| F4 | 4 sites | The "is this simple?" predicate exists in `AlarmSynchronizationService.swift:299`, `TickerService.swift:295`, plus two implicit copies: `Ticker.alarmKitSchedule`'s `switch` and `AlarmRegenerationService.queryCurrentAlarms:169` (`if case .fixed` — blind to `.relative`). All four must move in lockstep | CRITICAL |
| F6 | 4 sites | Schema disagreement over one App Group store: `figApp.swift:25-28` uses `Schema([Ticker.self, TickerCollection.self])`; `StopIntent.swift:27`, `OpenAlarmAppIntent.swift:23`, `WidgetDataFetcher.swift:194` use `Schema([Ticker.self])`. No `VersionedSchema`/`SchemaMigrationPlan` anywhere. The **widget can be the first process to open the store** after an update. Failure mode is `fatalError` → launch crash loop whose only remedy is deleting the app | CRITICAL |
| F10 | project-wide | **`SWIFT_VERSION = 5.0`** in the generated project despite `Tuist.swift` declaring `swiftVersion: "6.0"`; no `SWIFT_STRICT_CONCURRENCY` anywhere. CLAUDE.md's "Swift 6.0" claim is wrong. Live consequence: `synchronize` is a nonisolated `async` requirement awaited from a `@MainActor` method, so the entire reconciliation (`fetch`, mutate, `delete`, `save`) runs **off** the main actor on a `ModelContext` built on it, while `@Query` reads the same objects on main. `ModelContext` is not thread-safe | HIGH |
| F7 | `AlarmRegenerationService` | `queryCurrentAlarms` reads dates already shifted by the pre-alert; `calculateTargetDates` returns unshifted dates. The intersection in `computeDiff:194-205` is always empty, so **every regeneration cancels and recreates every alarm** | HIGH |
| F8 | `AlarmGenerationStrategy.swift:35-43` | `maxAlarms = nil` for two of three strategies; no global accounting | HIGH |
| F12 | `TickerScheduleExpander.swift:37` | `Calendar.current` is a snapshot that does not track timezone changes; `AlarmRegenerationService` is a `.singleton` holding it frozen. Fly NY→London and alarms land 5 hours off, while `WidgetDataFetcher.swift:50` re-reads `Calendar.current` per call and displays a *different* time than the alarm fires | MED |
| F13 | test suite | `AlarmServiceTests.swift` is a **1-line empty file**. `AlarmConfigurationBuilderTests.swift` (562 lines) asserts a tautology — `buildConfiguration` can never return nil. All ~60 sync tests run against the **real** `AlarmManager.shared` because `MockAlarmStateManager` falls through when `mockAlarms` is empty, and no test ever sets it | HIGH |
| S1–S5 | `StopIntent.swift` | `UUID(uuidString:)!` force-unwrap (`:45`); `fatalError` (`:41`); schema mismatch (`:27`); manual `Activity.end` racing AlarmKit (`:62-114`) — **a confidence-9 April 2026 learning, still unapplied**; `soundID.components(separatedBy:".")[1]` index crash (`AlarmConfigurationBuilder.swift:66-68`) | HIGH |
| S6/S7 | `Shared/`, `Ticker/Project.swift` | Dead code. **Resolved:** `Ticker.xcworkspace/contents.xcworkspacedata` references root `Ticker.xcodeproj`, so root `Project.swift` is live | LOW |

### Design findings (scorecard: hierarchy 2, states 2, journey 2, specificity 1, design-system 1/3, a11y 1, Island 1 — all /10)

| # | Finding | Sev |
|---|---|---|
| D1 | "Remove the alert gate" renders nothing. Every downstream component dead-ends on `.alert`: `countdown(state:)` → `default: EmptyView()` (`:281`), `AlarmProgressView:89` → same, `AlarmControls` has no `.alert` branch. It is a rewrite of four files, not a 5-line diff | CRITICAL |
| D2 | **Snooze is unreachable in every Live Activity surface.** `presentation.alert.secondaryButton` is never read in the widget target. At 7am the user reaches for Snooze first. Layout: Snooze large-left, Stop smaller-right — a mis-tap on Stop is unrecoverable | CRITICAL |
| D3 | `AlarmPresentation.Alert.stopButton` is `@available(*, deprecated)` in the 26.5 SDK and the iOS 26.1 init drops it entirely. `AlarmControls.swift:34` reads it; `buildPresentation:91-96` writes it via the deprecated init | CRITICAL |
| D4 | The fire time — `Mode.Alert.time`, the single most legible-in-one-second datum — is not in the plan's hierarchy at all | CRITICAL |
| D5 | Island colours route through `\.colorScheme` (`:329`, `:473`); `TickerColor.textPrimary` returns `absoluteBlack` in light appearance. The Island is always black → **black-on-black** | CRITICAL |
| D6 | **7 live `.repeatForever` sites** all keyed on values that never change, so no pulse animation in this product has ever run. Separately, `AlarmProgressView` reads `Date.now` at render time in a view that only re-renders on content-state pushes — **the progress ring is frozen for the whole countdown**. (The countdown *text* is fine: `Text(timerInterval:)` at `:274`, `:370`, `:471`) | CRITICAL |
| D7 | `TickerDesignSystem+Accessibility.swift` declares `extension View` with **no `public`** — internal to TickerCore, so `TickerWidgets` cannot call any of it. Zero usages. Stop button has no VoiceOver label (`ButtonView.swift:30` renders the glyph and ignores `config.text`) | HIGH |
| D8 | `Color(hex: metadata?.colorHex ?? "#000000") ?? TickerColor.primary` — repeated 5×. `Color.init?(hex:)` parses `"000000"` successfully, so **the fallback never fires**. A ticker with no colour renders a black dot on a black Island | MED |
| D9 | 17 raw `.system(size:)` calls in the Live Activity path opt out of Dynamic Type, which `Font+SFProRounded.swift` explicitly promises | MED |
| D10 | `TickerColor.danger` (#EC4899) on white is **3.66:1** — below WCAG AA. Touch targets ≈46pt; the design system's own `tapTargetPreferred = 56` is unused in the widget | HIGH |
| D11 | Expanded Island populates 1 of 4 regions; `expandedLeadingView` (`:316-360`) is defined and referenced nowhere. `minimalDynamicIslandView` overflows a ~24pt region | HIGH |

---

## Fix sequence (re-ordered by review)

Ordered so nothing lands on an untested or actively destructive foundation.

**Tier 0 — stop the bleeding (ship first, small, no schema change)**
- **P0a** Add `NSSupportsLiveActivities: true` to root `Project.swift`; run the
  device experiment to settle H1. *2 lines.*
- **P0b** Stop deleting user rows — restrict `tickersToDelete`
  (`AlarmSynchronizationService.swift:236-250`) to rows that were never
  user-authored. **This is RC4 and it needs no `firedAt` field.** *~5 lines.*
- **P0c** `buildSecondaryIntent` → use the occurrence ID, not `alarmItem.id` (F9). *1 line.*
- **P0d** Make rollback non-destructive in both `executeAtomicTransaction` and
  `TickerService` — adds before deletes, never delete a row you did not create (F5).

**Tier 1 — make the foundation safe**
- **P1** `SWIFT_STRICT_CONCURRENCY = complete` on TickerCore; fix the `ModelContext`
  isolation; then flip `SWIFT_VERSION` to 6.0 (F10). Prerequisite for any new writer.
- **P2** Introduce an `AlarmScheduling` protocol seam over `AlarmManager` — without
  it no error path in this plan is testable (F13).
- **P3** Unify all four `Schema(...)` sites on one `TickerSchema.current` in
  TickerCore, **shipped as its own release**; replace both `fatalError`s; introduce
  `VersionedSchema` while the only stage is a no-op (F6).

**Tier 2 — reliability**
- **P4** Telemetry that can actually observe the event (F1): launch-time inference
  (for each past `generatedAlarmKitIDs` entry absent from `AlarmManager.alarms`, emit
  `alarm_fired_inferred`) + reaction events from the intents that do run + an
  `alarms_expected_since_last_launch` denominator. Needs a cross-target seam, since
  `AnalyticsEvents` lives in the app target and TickerCore has zero `.track()` calls.
- **P5** Native `.weekdays` recurrence (RC0) **with** the one-shot upgrade migration
  (F2, cancel-then-schedule with verification) and the midnight-crossing weekday
  rotation (F3), touching all four predicate sites (F4). Also update
  `Alarm.alertingTime` (`TickerService.swift:612-645`), which ignores recurrence
  weekdays and will otherwise show "next: tomorrow 7am" on a Saturday.
- **P6** Global alarm budget + `maximumLimitReached` handling (RC7, F8).
- **P7** `computeDiff` date normalization (F7) + window origin (RC5) +
  `Calendar.autoupdatingCurrent` (F12) + call `scheduleBackgroundTask()` at launch +
  foreground regeneration (RC3). State the reliability ceiling honestly: for schedule
  types that need expansion, correctness depends on the app being opened.

**Tier 3 — the Live Activity**
- **P8** Rewrite `.alert` rendering across all four files on the iOS 26.1 API (RC1,
  D1–D11). Per-surface spec:
  - *minimal:* one pulsing `bell.badge.fill` via `.symbolEffect(.pulse, options: .repeating)`
  - *compactLeading:* tinted icon; *compactTrailing:* fire time, monospaced, `lineLimit(1)`
  - *expanded:* leading = icon + label, trailing = fire time, bottom = Snooze + Stop at ≥56pt
  - *lock screen:* fire time at `TimeDisplay()`, label at `Title3()`, Snooze + Stop full-width; drop the "Ticker" wordmark
  - Make the accessibility extension `public`; label every control from `AlarmButton.text`; pin Island colours to a fixed light-on-dark palette; delete all 7 `.repeatForever`; replace the frozen ring with `ProgressView(timerInterval:)`
- **P9** Harden the intents: S1–S5.

**Deferred to a separate cleanup PR:** S6 (delete `Shared/`), S7 (delete
`Ticker/Project.swift`).

---

## Not in scope

- Rewriting the expansion pipeline for `hourly`/`biweekly`/`monthly`/`yearly`/`every`
  — P5 demotes them to a tail feature; a redesign is separate work.
- Snooze/repeat UX redesign beyond making the existing secondary button reachable.
- Deleting `Shared/` and the duplicate Tuist project (diff noise on a change that
  must stay revertible).
- Any new user-facing feature. Per the CEO voice: differentiated features are worth
  negative value until the fire rate is instrumented and green.

## What already exists (leverage, don't rebuild)

| Need | Already there |
|---|---|
| Weekday recurrence | `Ticker.swift:341-349` already builds `.weekly([...])` for `.daily` |
| Rate limiting | `RegenerationRateLimiter` — wire it to the foreground trigger |
| Schedule expansion | `TickerScheduleExpander` + 1370 lines of genuine tests |
| Analytics transport | PostHog wired, ~158 events — it just needs an alarm-fired event and a TickerCore seam |
| Accessibility helpers | `TickerDesignSystem+Accessibility.swift` — exists, just not `public` |
| Design tokens | `tapTargetPreferred = 56`, `buttonHeightLarge = 64` — defined, unused in the widget |

## Dream state delta

```
  CURRENT                          THIS PLAN                    12-MONTH IDEAL
  Alarms fail silently.      -->   Fire rate is measured    --> Reliability is a
  Nobody knows. Found by           and alerts on drop.          tracked SLO. New
  one user complaint.              Common alarms use            features gated on
  Most common alarm rides          native recurrence.           it staying green.
  a pipeline that never            User data is never
  re-runs. Reconciliation          deleted by reconciliation.
  deletes user data.
```

## Error & rescue registry

| Error | Trigger | Caught where | User sees | Tested |
|---|---|---|---|---|
| `AlarmError.maximumLimitReached` | budget exhausted | **nowhere** | nothing; alarms silently stop | No → P6 |
| `schedule()` throws | invalid config (RC2) | `TickerService:278` → **deletes the ticker** | alarm vanishes | No → P0d |
| `cancel()` throws | stale ID | `try?` at `:328` — swallowed | double-fire risk | No → P5 |
| SwiftData migration failure | schema mismatch (F6) | `fatalError` | **launch crash loop** | No → P3 |
| `UUID(uuidString:)!` nil | malformed intent param | force-unwrap | intent process crash | No → P9 |
| `components(separatedBy:".")[1]` | sound name without a dot | none | crash on schedule | No → P9 |
| Secondary intent throws (F9) | `.openApp` default | none | alarm keeps ringing, app opens | No → P0c |

## Failure modes registry

| Mode | Detectable today? | After plan |
|---|---|---|
| Alarm never fires | **No** | Yes — P4 inference + ratio alert |
| Ticker deleted after firing | No | Prevented (P0b) + test |
| `.weekdays` expansion runs out | No | Structurally impossible (P5) |
| Budget exhaustion | No | Yes — P6 counts and surfaces |
| Migration crash loop | No (crash only) | Recoverable (P3) |
| Blank Dynamic Island | Visual only | Previews + zero-`repeatForever` build check |

## Cross-phase themes (raised independently in 2+ phases — high confidence)

1. **P8 does not fix the ringing.** Design and Eng both concluded the Live Activity
   rewrite has zero effect on whether the alarm rings. Reflected in the re-ordering.
2. **The deprecated `stopButton` API.** Design D3 and Eng F15 independently.
3. **Unapplied April 2026 learnings.** CEO and Design independently: a confidence-9
   learning naming `StopIntent.swift` is still unapplied four months later. The
   project's failure mode is landing fixes, not finding them.
4. **Detection is absent and load-bearing.** CEO raised it; Eng then proved the
   originally proposed mechanism (`alarmUpdates`) cannot observe the event.

## Verification

See the test plan artifact. Gate on: the four Tier-0 items shipping behind tests,
`NSSupportsLiveActivities` asserted in the generated plist, zero `.repeatForever` in
`TickerWidgets`, and the two tests that currently assert RC4 rewritten to assert the
opposite.

---

<!-- AUTONOMOUS DECISION LOG -->
## Decision Audit Trail

| # | Phase | Decision | Class | Principle | Rationale | Rejected |
|---|-------|----------|-------|-----------|-----------|----------|
| 1 | Phase 0 | Author a plan from investigation rather than ask for one | Mechanical | P6 action | Input was a bug report, not a plan | Blocking to ask for a plan file |
| 2 | Phase 0 | UI scope = yes, DX scope = no | Mechanical | — | Lock-screen layout + Island + buttons; consumer app, not a dev tool | Running Phase 3.5 |
| 3 | Phase 0.5 | Proceed `[subagent-only]` after Codex SIGKILL | Mechanical | P6 action | Verified twice, sandbox on and off | Blocking on Codex |
| 4 | CEO | Demote H1 (`NSSupportsLiveActivities`) from root cause to hypothesis | Taste | P5 explicit | Absence verified; causation not. Counter-evidence in April learnings | Keeping it as root cause #1 |
| 5 | CEO | Delete the `postAlert` causal claim | Mechanical | P5 explicit | Factually wrong; it is the snooze delay, not ring duration | Retaining it |
| 6 | CEO | Add RC0 (native `.weekdays`) as the framing insight | Taste | P2 boil lakes | SDK:170 verified; collapses 3 "bugs" into 1 routing decision | Treating RC3/4/5 as independent |
| 7 | CEO | Correct S8 — PostHog is wired, the gap is alarm-specific | Mechanical | P5 explicit | 158 events, 0 `.track()` in TickerCore, 251 `print()` | Original wording |
| 8 | CEO | Promote detection (RC6) to Tier 2 with a working mechanism | Taste | P1 completeness | Undetectable failure is the meta-bug | Shipping fixes blind |
| 9 | Design | Accept D1 — P8 is a 4-file rewrite, not a gate removal | Mechanical | P5 explicit | Verified: 3 downstream components dead-end on `.alert` | "Remove the gate" |
| 10 | Design | Adopt the per-surface Island/lock-screen spec verbatim | Taste | P1 completeness | Spec-by-implementer is how the blank Island shipped | Leaving P8 as prose |
| 11 | Design | Snooze large-left, Stop smaller-right | Taste | P5 explicit | Mis-tap on Stop is unrecoverable; matches Clock muscle memory | Stop as primary |
| 12 | Design | Migrate off deprecated `stopButton` now | Mechanical | P2 boil lakes | Verified deprecated in 26.5; 26.1 init drops it | Building more on it |
| 13 | Eng | Reject `alarmUpdates` as the telemetry mechanism | Mechanical | P5 explicit | In-process; cannot observe a fire while the app is dead | Original P0 |
| 14 | Eng | Split RC4 fix from `firedAt` schema change | Taste | P3 pragmatic | ~5 lines ships today; migration is separate risk | Coupling them |
| 15 | Eng | Strict concurrency as a Tier-1 prerequisite | Taste | P1 completeness | P4 adds a third writer to a store with a live data race | Deferring to follow-up |
| 16 | Eng | Ship schema unification as its own release | Taste | P5 explicit | Failure mode is an unrecoverable launch crash loop | One combined release |
| 17 | Eng | Add the `AlarmScheduling` seam | Mechanical | P1 completeness | Without it no error path is testable | Untestable error paths |
| 18 | Eng | Require the `.weekdays` upgrade migration | Mechanical | P2 boil lakes | Without it, existing users' alarms die silently in ≤7 days | Ship P5 bare |
| 19 | Eng | Fix midnight-crossing weekday rotation | Mechanical | P5 explicit | `days.map(\.localeWeekday)` is wrong by 24h weekly | One-line map |
| 20 | Eng | Collapse 4 predicate copies into one derived property | Mechanical | P4 DRY | Drift becomes impossible by construction | Editing 4 sites |
| 21 | Eng | Rewrite the 2 tests that assert RC4 is correct | Mechanical | P5 explicit | They will turn red and invite a revert | Leaving them |
| 22 | All | Defer S6/S7 to a separate cleanup PR | Taste | P3 pragmatic | Diff noise on a change that must stay revertible | Bundling |

---

## Implementation status — all tiers landed

Build: `BUILD SUCCEEDED` (app + TickerCore + TickerWidgets).
Tests: **237 executed, 0 failures.**

| Item | Status | Notes |
|---|---|---|
| P0a `NSSupportsLiveActivities` + `UIBackgroundModes` | Done | Asserted present in the generated plist. `processing` deliberately omitted — no `BGProcessingTaskRequest` is ever submitted |
| P0b Stop deleting user rows (RC4) | Done | Spent tickers are *retired* (`isEnabled = false`), never deleted |
| P0c Secondary intent occurrence ID (F9) | Done | |
| P0d Non-destructive rollback (F5) | Done | Adds before deletes; `didInsert` guard so a failed reschedule cannot delete a pre-existing row |
| P1 Strict concurrency + `ModelContext` isolation | Partial | `SWIFT_STRICT_CONCURRENCY = complete` on TickerCore; the alarm-pipeline races fixed via `@MainActor`. ~120 peripheral warnings remain visible (haptics, Factory closures, `UpcomingAlarmPresentation: Sendable`) — deliberately left as diagnostics rather than a framework-wide refactor riding this change |
| P2 `AlarmScheduling` seam | Done | Plus `TestAlarmFactory`, which builds real `Alarm` values via `Codable`, and `FakeAlarmScheduler` with `maximumLimitReached` injection |
| P3 Schema unification | Done | One `TickerSchema.current` + `VersionedSchema` + `SchemaMigrationPlan`; all 4 sites rewired; both `fatalError`s replaced |
| P4 Telemetry that can observe a fire | Done | Occurrence log + absence inference + intent reactions + expected-count denominator. `alarmUpdates` deliberately not used |
| P5 Native `.weekdays` + migration | Done | Includes midnight-crossing weekday rotation and a verified cancel-then-schedule migration |
| P6 Alarm budget + `maximumLimitReached` | Done | Global 64 / per-ticker 32; every strategy now bounded |
| P7 `computeDiff` / window origin / Calendar / BG task / foreground | Done | |
| P8 Live Activity alert rendering | Done | All four surfaces; snooze reachable; deprecated `stopButton` avoided; frozen ring replaced; Island colours pinned |
| P9 Intent hardening | Done | |

### Deviations from the reviewed plan

1. **No `firedAt` schema attribute.** The eng review argued P1 does not need it, and it turned out nothing else does either: fire detection uses an App Group occurrence log, which is transient bookkeeping rather than user data. This removes the entire migration-risk class — `VersionedSchema` still ships, with V1 describing the existing shape as a no-op, so the machinery is in place before the first real change needs it.
2. **Schema unification did not ship as its own release** (the plan recommended it). Everything is in one changeset here. The recommendation still stands for rollout: ship the unified-schema build first, confirm it opens cleanly across app/widget/intent, then ship the rest.
3. **`AlarmBudget` caps raised** from 48/16 to 64/32 during implementation. At 16 an hourly ticker only covered 16 of its 48-hour window, which is under the 24-hour regeneration threshold.
4. **`AlarmServiceTests.swift` deleted** — it was a 1-byte empty file that made the suite look like it covered `TickerService`.
5. **S6/S7 still deferred** as planned (`Shared/`, `Ticker/Project.swift`).

### Still not proven

**H1 remains a hypothesis.** `NSSupportsLiveActivities` is now set, which is correct regardless, but nothing here establishes that its absence was causing the blank Dynamic Island. The device experiment in the Verification section is still the way to settle it — and it is now unfalsifiable on this build, so if it matters, test it against the previous build.
