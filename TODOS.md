# TODOS

## Alarms

### Tell the user when the alarm budget is full

**What:** Surface a user-visible indication when a ticker could not arm all of its
occurrences because the global or per-ticker alarm budget was reached.

**Why:** v1.4 added a budget (64 global, 32 per ticker) and reports exhaustion to
telemetry, so we can now see it happening. The person holding the phone still
sees nothing — their alarm simply does not ring. The plan's own error registry
listed this row as "user sees: nothing; alarms silently stop" and assigned P6 to
close it; P6 made it visible to us, not to them.

**Context:** `AlarmBudget.allowance` is the gate, and
`AlarmRegenerationService.executeAtomicTransaction` is where trimming happens and
where `alarmBudgetExhausted` is raised. Because per-ticker is 32 and global is 64,
two saturating tickers exhaust the budget and every ticker after that gets zero
alarms. Needs a design decision about where the warning belongs — the alarm row,
the add/edit flow, or both. Do not just raise the caps: the conservative ceiling
exists to stay clear of AlarmKit's own opaque limit.

**Effort:** M
**Priority:** P1
**Depends on:** None

### Decide how retired alarms count in the fire-rate denominator

**What:** `AlarmFireDetector.expectedFireCount` filters on `ticker.isEnabled`, but
reconciliation retires a spent one-time ticker by setting `isEnabled = false`
after it fires. A fired one-shot alarm therefore counts in the numerator and then
removes itself from the denominator.

**Why:** The fire rate is the number v1.4 exists to produce, and it will read
above 100% whenever one-time alarms fire, with nothing indicating why. Anyone
reading the dashboard cannot tell a healthy release from a measurement artifact.

**Context:** Interaction between two individually-correct fixes: P0b (retire
rather than delete) and P4 (the expected-count denominator). Options are to count
retired-but-fired tickers in the denominator, to segment one-time alarms out of
the metric, or to define the metric as recurring-alarms-only. This is a metric
definition call, not a bug fix — settle it before reading the dashboard, not
after.

**Effort:** S
**Priority:** P1
**Depends on:** None

### Finish Dynamic Type in the Live Activity

**What:** Six raw `.system(size:)` calls remain in the Dynamic Island regions of
`AlarmLiveActivity.swift`.

**Why:** `Font+SFProRounded.swift` promises Dynamic Type throughout, and the
alarm surfaces are exactly where someone with larger text set needs it. The lock
screen was converted in v1.4; the Island was deliberately left fixed.

**Context:** The Island regions have hard geometry and scaling text clips them,
which is why they were left alone. Doing this properly means Dynamic Type with a
`dynamicTypeSize` cap per region, verified on device at several text sizes. The
design review's D9 counted 17 such calls originally; 6 remain and they are all
Island.

**Effort:** M
**Priority:** P3
**Depends on:** Device verification at multiple accessibility text sizes

## Design

### WCAG Contrast Audit

**What:** Audit all schedule badge color + white text combinations for WCAG AA
compliance (4.5:1 minimum for small text).

**Why:** Several badge colors are likely below AA against white, making schedule
labels hard to read.

**Context:** Likely failures are `#33CCCC` (teal, "Every N") at an estimated
~2.5:1 with white, and `#84CC16` (lime, "Daily") at ~2.8:1. Fix options: use a
darker variant of each color, switch badge text to dark for low-contrast
backgrounds, or add a semi-transparent dark overlay behind the text. Reference the
Schedule Badge Colors table in `DESIGN.md`. Related: the design review also
flagged `TickerColor.danger` (#EC4899) at 3.66:1 on white.

**Effort:** S
**Priority:** P2
**Depends on:** None

### Design System Consolidation

**What:** Decide on a single canonical design system source. Both are currently
used interchangeably across 35+ views.

**Why:** Two sources of truth for tokens means UI drifts between screens
depending on which system a given view happened to use.

**Context:** The two are **DesignKit** (external SPM package,
`mayankgandhi/DesignKit`, shared across projects) and **TickerDesignSystem**
(internal, `TickerCore/Sources/TickerCore/UI/TickerDesignSystem.swift`,
app-specific). Options: (1) make DesignKit the single source and remove
TickerDesignSystem, (2) make TickerDesignSystem the single source and use
DesignKit only for shared components, (3) keep both with automated sync
validation. Current mitigation: `DesignTokenValidationTests.swift` validates token
parity at build time.

**Effort:** L
**Priority:** P2
**Depends on:** None

## Cleanup

### Delete the uncompiled Shared/ directory

**What:** Remove `Shared/` (23 files) and the duplicate root `Ticker/Project.swift`.

**Why:** `Shared/` contains a full duplicate of `TickerDesignSystem.swift`,
`Font+SFProRounded.swift`, `Ticker.swift` and more, and none of it is compiled —
no `Project.swift` sources glob references `Shared/**`. It reads as live code and
is not, so people edit it expecting an effect. Upstream edited
`Shared/TickerDesignSystem.swift` during the v1.4 cycle, changing nothing.

**Context:** Deferred from the alarm reliability plan as S6/S7 to keep that
changeset revertible. Verify no glob picks it up before deleting, then remove in
one commit that touches nothing else. Note the divergence is already real: the
`Shared/` copy lacks the `stop` and `snooze` tokens v1.4 added.

**Effort:** S
**Priority:** P3
**Depends on:** None

### Remove or use IntentError

**What:** `TickerCore/Sources/TickerCore/AppIntents/LiveActivity/IntentError.swift`
is unreferenced.

**Why:** Dead code in a framework's public API surface. It suggests a
throwing-on-malformed-ID convention the intents deliberately do not follow.

**Context:** Arrived from `main` during the v1.4 merge, which added it alongside
intents that threw `IntentError.invalidAlarmID` on a malformed alarm ID. The merge
kept this branch's intent implementations instead, which log and no-op rather than
throwing at a user holding a ringing phone — leaving the type with no callers.
Either delete it or adopt throwing deliberately; do not leave it ambiguous.

**Effort:** S
**Priority:** P4
**Depends on:** None

## Completed

_Nothing yet. Items move here with a `**Completed:** vX.Y (YYYY-MM-DD)` annotation._
