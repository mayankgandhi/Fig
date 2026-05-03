# Ticker Design System

Mission-critical design system for urgent, reliable alarm management.

**Aesthetic**: Warm, rounded, glass-forward. SF Pro Rounded everywhere. Orange/amber brand palette with high-contrast alarm state colors. Layered brand background gradients with subtle depth. Spring animations for tactile feedback.

**Principles**:
- Content-first hierarchy with Liquid Glass material
- Color-coded alarm states for instant recognition
- Haptic + visual feedback on every critical action
- Full Dynamic Type & accessibility support
- iOS 26+ Liquid Glass design patterns

> **DesignKit Relationship**: The external `DesignKit` package (SPM, `mayankgandhi/DesignKit`) is the canonical shared design system. `TickerDesignSystem` in `TickerCore` is the internal implementation that mirrors identical token values. Both must stay in sync — any token change requires updating both `TickerCore/Sources/TickerCore/UI/TickerDesignSystem.swift` and `Ticker/Sources/App/TickerDesignKitConfiguration.swift`.

---

## Color System

> Source: `TickerCore/Sources/TickerCore/UI/TickerDesignSystem.swift` (`TickerColor`)

### Brand Colors

| Token | Hex | Swatch | RGB | Use |
|-------|-----|--------|-----|-----|
| `primary` | `#F97330` | :orange_circle: | 0.976, 0.451, 0.188 | Primary actions, tint color |
| `primaryDark` | `#E9561B` | :orange_circle: | 0.914, 0.337, 0.106 | Pressed/hover state |
| `accent` | `#F99D2B` | :yellow_circle: | 0.976, 0.616, 0.169 | Golden amber accent |

### Semantic Colors

| Token | Hex | Swatch | RGB | Use |
|-------|-----|--------|-----|-----|
| `success` | `#84CC16` | :green_circle: | 0.518, 0.800, 0.086 | Vibrant lime, positive |
| `warning` | `#EF4444` | :red_circle: | 0.937, 0.267, 0.267 | Red, caution |
| `danger` | `#EC4899` | :red_circle: | 0.925, 0.247, 0.600 | Hot pink, destructive |

### Alarm State Colors

| Token | Hex | Swatch | RGB | State |
|-------|-----|--------|-----|-------|
| `scheduled` | `#F98947` | :orange_circle: | 0.976, 0.537, 0.278 | Warm coral - scheduled |
| `running` | `#84CC16` | :green_circle: | 0.518, 0.800, 0.086 | Electric lime - active |
| `paused` | `#94A3B8` | :white_circle: | 0.580, 0.639, 0.722 | Slate blue-gray - paused |
| `alerting` | `#D946EF` | :purple_circle: | 0.851, 0.275, 0.937 | Bright fuchsia - ringing |
| `disabled` | `#959598` | :white_circle: | 0.584, 0.584, 0.596 | Neutral gray |

### Schedule Badge Colors

| Schedule | Hex | RGB | Badge Text |
|----------|-----|-----|------------|
| One-time | `#0EA5E9` | 0.055, 0.647, 0.914 | "Once" |
| Daily | `#84CC16` | 0.518, 0.800, 0.086 | "Daily" |
| Weekdays | `#6699CC` | 0.400, 0.600, 0.800 | "Weekdays" |
| Hourly | `#CC6633` | 0.800, 0.400, 0.200 | "2h" |
| Every N | `#33CCCC` | 0.200, 0.800, 0.800 | "30m" / "2d" |
| Biweekly | `#9966CC` | 0.600, 0.400, 0.800 | "Biweekly" |
| Monthly | `#E69933` | 0.900, 0.600, 0.200 | "Monthly" |
| Yearly | `#CC3366` | 0.800, 0.200, 0.400 | "Yearly" |

### Surface & Text (Color-scheme adaptive)

| Token | Dark Mode | Light Mode |
|-------|-----------|------------|
| `background()` | `#000000` (absoluteBlack) | `#FFFFFF` (absoluteWhite) |
| `surface()` | `#1C1C1E` (surfaceDark) | `#F5F5F7` (surfaceLight) |
| `textPrimary()` | White 100% | Black 100% |
| `textSecondary()` | White 70% | Black 70% |
| `textTertiary()` | White 50% | Black 50% |

---

## Brand Background Gradient

> `TickerColor.liquidGlassGradient(for:)` — 5-layer ZStack used as the base background on all screens. Named "Brand Background Gradient" to avoid confusion with Apple's `.glassEffect()` Liquid Glass API.

### Dark Mode Stack
1. **Base**: Linear gradient — soft charcoal (`0.04`) to warm gray (`0.06`) to neutral (`0.04`)
2. **Mid-layer**: Diagonal — `primary` at 4% + `accent` at 3% opacity
3. **Radial depth**: Center glow — `primary` at 2% opacity (50→400 radius)
4. **Top shimmer**: White 3%→1% (top to center)
5. **Bottom glow**: `primary` 3% + `primaryDark` 2% (center to bottom)

### Light Mode Stack
1. **Base**: Linear gradient — warm cream (`0.99, 0.96, 0.93`) through peach-white, ivory, champagne
2. **Mid-layer**: Diagonal — `primary` at 6% + `accent` at 4% opacity
3. **Radial depth**: White center at 40% opacity (100→500 radius)
4. **Top luminance**: White 30%→10% (top to center)
5. **Bottom tint**: `primary` 4% + `accent` 3% (center to bottom)

### Usage Pattern
```swift
ZStack {
    TickerColor.liquidGlassGradient(for: colorScheme)
        .ignoresSafeArea()
    Rectangle()
        .fill(.ultraThinMaterial)
        .opacity(0.1)  // 0.5 for sheets
        .ignoresSafeArea()
}
```

---

## Glass Usage Guide

> When to use Apple's `.glassEffect()` Liquid Glass vs flat/calm surfaces.

### Use Glass Material FOR
| Context | Why |
|---------|-----|
| Sheet backgrounds | Depth cue for modal layers |
| Active/alerting alarm cards | Draws attention to urgent state |
| Floating action buttons | Elevation over content |
| Clock face (TodayClockView) | Visual anchor — product signature |

### Use Flat/Calm Surfaces FOR
| Context | Why |
|---------|-----|
| Alarm list rows | Scannable, low visual noise |
| Settings screens | Utility, not showcase |
| Form inputs & pickers | Glass competes with input focus |
| Navigation bars | Standard system chrome |

### Rules
- Never stack glass-on-glass (glass cannot sample other glass)
- Never use `.glassEffect()` inside scrollable content areas
- Limit simultaneous glass effects onscreen for performance
- The **TodayClockView analog clock face** is the product's visual anchor — it should always have glass treatment

---

## Typography

> Source: `TickerCore/Sources/TickerCore/Extensions/Font+SFProRounded.swift`
>
> Font family: **SF Pro Rounded** — all styles. Full Dynamic Type scaling.

### Type Scale

| Modifier | Base Size | Weight | Use |
|----------|-----------|--------|-----|
| `.LargeTitle()` | 34pt | Bold | Section titles ("Tickers") |
| `.Title()` | 28pt | Bold | Main headers, time display |
| `.Title2()` | 22pt | Bold | Section headers |
| `.Title3()` | 20pt | Semibold | Ticker names |
| `.Headline()` | 17pt | Semibold | Primary emphasis |
| `.Body()` | 17pt | Regular | Main content |
| `.Callout()` | 16pt | Regular | Secondary content |
| `.Subheadline()` | 15pt | Semibold | Detail text, button labels |
| `.Footnote()` | 13pt | Medium | Small labels |
| `.Caption()` | 12pt | Medium | Metadata |
| `.Caption2()` | 11pt | Regular | Minimal text |

### Semantic Shortcuts

| Modifier | Maps To | Use |
|----------|---------|-----|
| `.TimeDisplay()` | Title (28pt) | Card time displays |
| `.TickerTitle()` | Title3 (20pt) | Ticker names |
| `.DetailText()` | Subheadline (15pt) | Schedule details |
| `.ButtonText()` | Footnote (13pt) | Buttons, small labels |
| `.SmallText()` | Caption (12pt) | Secondary info |

---

## Component Hierarchy

> Visual hierarchy rules for each major view. Elements are ordered by prominence.

### Navigation Model
- **2-tab layout**: Today | Scheduled
- **Settings**: Toolbar gear icon (not a tab)

### AlarmCell (`AlarmCell.swift`)

| Element | Role | Style | Size |
|---------|------|-------|------|
| Time | Primary | `.Title()` | 28pt Bold |
| Label | Secondary | `.Title3()` | 20pt Semibold |
| Schedule badge | Tertiary | `.Caption2()` | 11pt via `tickerStatusBadge` |
| State icon | Supporting | SF Symbol | 16pt |

> **Recommendation**: Consider increasing time to 28pt Title for clearer hero element.

### TodayClockView (`TodayClockView/`)

| Element | Role | Notes |
|---------|------|-------|
| Analog clock | Hero/anchor | Glass treatment, product signature |
| Next alarm countdown | Secondary | Below clock |
| Upcoming alarm list | Tertiary | Scrollable list |

### AddTickerView (`AddTickerView/`)

| Element | Role | Sub-components |
|---------|------|----------------|
| Time picker | Primary | `TimePickerCard` |
| Schedule type pills | Secondary | `OptionsPillsView` |
| Configuration fields | Tertiary | Label, icon, sound, countdown |

### ContentView (`ContentView.swift`)

| Element | Role | Sub-components |
|---------|------|----------------|
| Alarm list | Primary | `UnifiedAlarmListView` → `AlarmCell` |
| Empty state | Fallback | `ContentUnavailableView` |
| Toolbar | Chrome | Add button, settings |

---

## Spacing

> Source: `TickerSpacing`

| Token | Value | Use |
|-------|-------|-----|
| `xxs` | 4pt | Micro spacing |
| `xs` | 8pt | Tiny spacing |
| `sm` | 12pt | Small gaps |
| `md` | 16pt | Base unit (default padding) |
| `lg` | 24pt | Medium-large gaps |
| `xl` | 32pt | Large spacing |
| `xxl` | 48pt | Extra large |
| `xxxl` | 64pt | Section breaks |

### Component Sizes

| Token | Value | Use |
|-------|-------|-----|
| `tapTargetMin` | 44pt | Minimum tap target (44x44) |
| `tapTargetPreferred` | 56pt | Preferred for critical actions |
| `buttonHeightLarge` | 64pt | Primary action buttons |
| `buttonHeightStandard` | 48pt | Secondary buttons |

---

## Corner Radius

> Source: `TickerRadius`

| Token | Value | Use |
|-------|-------|-----|
| `none` | 0pt | Sharp corners |
| `tight` | 4pt | Status badges |
| `small` | 8pt | Small elements |
| `medium` | 12pt | Buttons, primary cards |
| `large` | 16pt | Cards, sheets |
| `xlarge` | 24pt | Large feature cards |
| `full` | 999pt | Circles, capsules |

---

## Shadows

> Source: `TickerShadow`

| Token | Opacity | Radius | Y Offset | Use |
|-------|---------|--------|----------|-----|
| `critical` | 30% black | 8pt | 4pt | Primary buttons, critical elements |
| `elevated` | 15% black | 12pt | 6pt | Elevated surfaces, floating cards |
| `subtle` | 8% black | 4pt | 2pt | Cards, mild depth |

---

## Animation

> Source: `TickerAnimation`

| Token | Duration | Curve | Use |
|-------|----------|-------|-----|
| `instant` | 0.1s | easeOut | Critical action feedback |
| `quick` | 0.2s | easeInOut | Button press, UI feedback |
| `standard` | 0.3s | easeInOut | Transitions, layout changes |
| `pulse` | 1.0s | easeInOut (forever, autoreverses) | Active alarm indicator |
| `spring` | response 0.3s, damping 0.7 | Spring | Tactile interactions |

### Common Spring Configs in Views
- **Icon selection**: response 0.2, damping 0.7
- **Option pills**: response 0.4, damping 0.7
- **Permission sheets**: response 0.4, damping 0.8
- **Time picker**: response 0.3
- **Clock alarm appear**: response 0.6, damping 0.8

---

## Button Styles

### Primary (`tickerPrimaryButton()`)
- Height: **64pt** | Radius: **12pt** | Full width
- Text: `.Subheadline()` in absolute white
- Background: `primary` orange (or `danger` pink if destructive)
- Shadow: `critical` (8pt blur, 30% black)
- Press: 85% opacity + 98% scale
- Disabled: `disabled` gray background

### Secondary (`tickerSecondaryButton()`)
- Height: **48pt** | Radius: **12pt** | Full width
- Text: `.Subheadline()` in `textPrimary`
- Background: `surface` color
- Border: 2pt stroke in `textTertiary`
- Press: 70% opacity + 98% scale

### Tertiary (`tickerTertiaryButton()`)
- Padding: 16pt horizontal, 12pt vertical
- Text: `.Subheadline()` in `textPrimary`
- No background
- Press: 50% opacity + 96% scale

---

## View Modifiers

### `.tickerStatusBadge(color:)`
- Text: `.ButtonText()`, uppercase
- Foreground: absolute white
- Padding: 12pt horizontal, 4pt vertical
- Radius: `tight` (4pt)
- Background: provided color

### `.tickerCard()`
- Background: `surface` (adaptive)
- Radius: `large` (16pt)
- Shadow: `subtle`

---

## Icon System

> Source: `TickerIcons` — all SF Symbols

### Alarm States
| Token | Symbol |
|-------|--------|
| `alarmScheduled` | `alarm` |
| `alarmRunning` | `alarm.fill` |
| `alarmPaused` | `pause.circle.fill` |
| `alarmAlerting` | `bell.badge.fill` |

### Actions
| Token | Symbol |
|-------|--------|
| `add` | `plus.circle.fill` |
| `delete` | `trash.fill` |
| `edit` | `pencil` |
| `settings` | `gearshape.fill` |
| `close` | `xmark` |
| `checkmark` | `checkmark` |

### Time / Schedule
| Token | Symbol |
|-------|--------|
| `calendar` | `calendar` |
| `clock` | `clock.fill` |
| `timer` | `timer` |
| `repeat` | `repeat` |

### Status Indicators
| Token | Symbol |
|-------|--------|
| `warning` | `exclamationmark.triangle.fill` |
| `error` | `xmark.circle.fill` |
| `success` | `checkmark.circle.fill` |
| `info` | `info.circle.fill` |

### Common View Symbols
- Navigation: `calendar.day.timeline.left`, `alarm`, `gearshape.fill`
- Sleep: `bed.double.fill`, `sunrise.fill`, `moon.zzz.fill`
- AI: `apple.intelligence`
- Activities: `figure.run`, `figure.yoga`, `dumbbell`, `fork.knife`, `cup.and.saucer`, `briefcase.fill`, `pills.fill`

---

## Haptics

> Source: `TickerHaptics`

| Method | Feedback | When |
|--------|----------|------|
| `criticalAction()` | Heavy impact | Setting/saving alarm |
| `standardAction()` | Medium impact | Standard interactions |
| `success()` | Success notification | Alarm confirmed |
| `warning()` | Warning notification | Alarm about to trigger |
| `error()` | Error notification | Failed action |
| `selection()` | Selection changed | Picker/toggle changes |

---

## Interaction States

> Patterns for empty, error, loading, disabled, and success states across the app.

### Empty State
- **Pattern**: `ContentUnavailableView` (system component)
- **Typography**: Title3 heading + Body description
- **CTA**: Capsule-shaped primary button
- **Implementation**: `EmptyStateView.swift`

### Error / Warning
- **Pattern**: `ValidationBanner` — inline banner below trigger element
- **Typography**: Footnote with warning icon
- **Color**: `warning` (red) background at 10% opacity
- **Implementation**: `ValidationBanner.swift`

### Loading
- **Pattern**: `ProgressView` with `primary` tint
- **Usage**: During alarm generation, data sync

### Disabled Alarm
- **Opacity**: 0.5 on entire cell
- **Text color**: `textTertiary`
- **Icon**: Grayscale treatment
- **Interactive**: Tap still opens detail (to re-enable)

### Success Confirmation
- **Haptic**: `success()` notification feedback
- **Visual**: Brief scale + opacity pulse on saved element

> **Gaps (future work)**: ContentView has empty state only — no loading or error states. AddTickerView has validation banners but no loading state during save.

---

## User Journeys

> Emotional arc of the alarm lifecycle mapped to design decisions.

### 1. CREATE — Calm, Focused
- **Context**: Sheet with large time picker
- **Tone**: Low visual noise, clear hierarchy
- **Haptic**: `success()` on save confirmation
- **Animation**: Spring (response 0.3) on dismiss

### 2. WAITING — Passive Confidence
- **Context**: Alarm in list, scheduled state
- **Tone**: Warm coral (`scheduled`), no animation
- **Goal**: User trusts the alarm is set, no anxiety

### 3. PRE-ALERT — Building Tension
- **Context**: Live Activity countdown begins
- **Tone**: Pulse animation starts, attention increases
- **Haptic**: None (save energy for alert)
- **Visual**: Countdown timer becomes prominent

### 4. ALERTING — Urgency
- **Context**: Alarm is ringing
- **Color**: Fuchsia (`alerting`) at full prominence
- **Haptic**: `warning()` repeating notification
- **Animation**: Pulse + scale (1.0→1.05 loop)
- **Glass**: Active card gets glass treatment

### 5. DISMISSED — Relief
- **Context**: User stops alarm
- **Color**: Transitions to `success` green briefly
- **Haptic**: `success()` notification
- **Animation**: Fade back to scheduled state
- **Tone**: Calm returns

---

## Accessibility

> Source: `TickerDesignSystem+Accessibility.swift`

- **Dynamic Type**: All typography uses SF Pro Rounded with `.system()` — scales automatically
- **Reduce Motion**: Checked via `@Environment(\.accessibilityReduceMotion)` — animations disabled/simplified
- **Adaptive Layout**: Compact vs accessible layout based on `sizeCategory`
- **VoiceOver**: All icons have accessible labels (via `IconMetadata`), buttons have hints, elements are grouped with combined labels
- **Contrast**: High-contrast text colors (100% vs 0% on backgrounds), semantic state colors chosen for differentiation

### Accessibility Modifiers

| Modifier | Purpose | Parameters |
|----------|---------|------------|
| `adaptiveAnimation(_:)` | Respects reduce motion; disables animation when on | `Animation` |
| `adaptiveAnimation(_:value:)` | Value-bound variant of above | `Animation`, `Equatable` value |
| `accessibleButton(label:hint:traits:)` | Standardized button accessibility | label, optional hint, traits |
| `accessibleIcon(_:label:)` | Accessible label for SF Symbol icons | systemName, label |
| `accessibleGroup(label:value:hint:)` | Groups related elements with combined label | label, optional value/hint |
| `adaptiveLayout(compact:accessible:)` | Switches layout at accessibility size categories | two `AnyLayout` |
| `accessibilityScaled(_:)` | Applies text style with full accessibility scaling | `Font.TextStyle` |
| `accessibleButtonTraits(_:)` | Adds `.isButton` plus optional additional traits | `AccessibilityTraits` |
| `accessibleHeaderTraits(_:)` | Adds `.isHeader` plus optional additional traits | `AccessibilityTraits` |

---

## Responsive Layout

> Size class and device adaptation rules.

### Size Class Rules
| Width Class | Layout | Notes |
|-------------|--------|-------|
| Compact (iPhone) | Single column | Full-width alarm list, stacked detail |
| Regular (iPad) | Optional 2-column | Master-detail split when space available |

### WCAG Contrast Notes
- Schedule badge colors `#33CCCC` (teal) and `#84CC16` (lime) with white text may not meet WCAG AA 4.5:1 contrast ratio for small text
- **Action needed**: Audit all badge color + white text combinations (tracked in TODOS.md)

### Disabled Alarm Visual Treatment
- Cell opacity: 0.5
- Text color: `textTertiary`
- Icon: Grayscale treatment
- Still tappable (opens detail to re-enable)

### iPad Keyboard Navigation
- Tab key navigates alarm list
- Enter key opens alarm detail
- Escape key dismisses sheets
