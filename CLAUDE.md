# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Ticker** (formerly "fig") is a SwiftUI iOS/iPadOS alarm application using SwiftData for persistence and AlarmKit for system alarm integration. The app features Live Activities, widgets, control center integration, and follows modern iOS 26+ Liquid Glass design patterns.

**Product Name**: Ticker
**Bundle ID**: m.fig
**Deployment Target**: iOS 26.0+
**Build System**: Tuist (for project generation)
**Swift Version**: Toolchain 6.0 (`Tuist.swift`), but targets compile in **Swift 5 language
mode** — `SWIFT_VERSION = 5.0` in the generated project. Tuist's `swiftVersion:` selects the
toolchain, not the language mode. TickerCore additionally sets
`SWIFT_STRICT_CONCURRENCY = complete`, so it gets full concurrency diagnostics without the
language-mode flip. Do not claim Swift 6 semantics apply project-wide.

## Architecture

This is a **multi-target Tuist project** with modular architecture organized into three main targets:

### 1. Ticker (Main App Target)
Located in `Ticker/Sources/`

**Entry Point**: `Ticker/Sources/App/figApp.swift` - Defines the main app structure, sets up SwiftData `ModelContainer` with `Ticker` model

**Key Directories**:
- `App/` - Main app views and app lifecycle
  - `figApp.swift` - App entry point
  - `AppView.swift` - Root view coordinating navigation
  - `ContentView.swift` - Main alarm list interface
  - `AddTickerView/` - Add/edit alarm flow with modular components
  - `TodayClockView/` - Today view showing clock and upcoming alarms
  - `AlarmDetailView.swift` - Detailed alarm view
  - `Components/` - Reusable UI components
  - `Services/` - App-level service coordination
  - `AITickerGeneration/` - Natural language alarm creation
- `Settings/` - Settings interface and menu items
- `Models/` - SwiftData models specific to the main app
- `DesignSystem/` - Design tokens and Liquid Glass components
  - `TickerDesignSystemPreviews.swift` - SwiftUI previews for design system
- `Utilities/` - Helper utilities
- `AlarmCell.swift` - Alarm list cell component

### 2. TickerCore (Framework Target)
Located in `TickerCore/Sources/TickerCore/`

**Purpose**: Shared business logic and models used across all targets (app, widgets, extensions)

**Key Components**:
- `Models/Ticker.swift` - Core `Ticker` SwiftData model with schedule, countdown, and presentation configuration. `alarmKitSchedule` is the single predicate for "can AlarmKit express this natively?" — `usesNativeAlarmKitSchedule` derives from it, and nothing should reimplement that test
- `Models/TickerSchema.swift` - **The only place** that builds a `Schema` or opens the App Group store. Four sites used to do it independently with disagreeing model sets; a mismatch risks an unrecoverable launch crash. Owns `VersionedSchema` + `SchemaMigrationPlan`
- `Models/AlarmBudget.swift` - Global (64) and per-ticker (32) caps on armed alarms, keeping the app clear of AlarmKit's own opaque limit
- `Services/AlarmScheduling.swift` - Protocol seam over `AlarmManager`, which cannot be constructed or subclassed. Without it no alarm error path is testable; `Container.alarmManager` vends `any AlarmScheduling`
- `Services/AlarmTelemetry.swift` - Telemetry facade + `AlarmReactionRecorder`. TickerCore raises events; the app target installs a PostHog sink
- `Services/AlarmFireDetector.swift` - Answers "did alarms fire?" by absence inference over `AlarmOccurrenceLog` plus drained intent reactions. **Not** `alarmUpdates`, which is in-process only and cannot observe a fire while the app is dead
- `Services/AlarmScheduleMigration.swift` - One-shot upgrade of expansion-backed weekday tickers to native recurrence. Cancels, verifies the cancel landed, then arms — skipping the ticker if verification fails, because arming over a live alarm means two alerts
- `AlarmMetadata.swift` - Shared data structures for alarm state synchronization
- `TickerScheduleExpander.swift` - Logic for expanding alarm schedules
- `AlarmOccurrenceService.swift` - Calculates alarm occurrences
- `AlarmHealth.swift` - Health monitoring for alarms
- `UI/TickerDesignSystem.swift` - Centralized design tokens and Liquid Glass components
- `ClockView.swift` - Shared clock UI component
- `UpcomingAlarmPresentation.swift` - Shared UI for upcoming alarms
- `ActivityIconMapper.swift` - Maps activities to icons
- `Models/AlarmGenerationStrategy.swift` - Strategies for generating alarms
- `Utilities/RegenerationRateLimiter.swift` - Rate limiting for alarm regeneration

**Note on `Shared/`**: the top-level `Shared/` directory is **not compiled into any
target** — no `Project.swift` sources glob references it. It holds stale duplicates of
`TickerDesignSystem.swift`, `Font+SFProRounded.swift`, `Ticker.swift` and others. Edit the
`TickerCore/Sources/TickerCore/` copies; editing `Shared/` changes nothing at runtime.

### 3. TickerWidgets (App Extension Target)
Located in `TickerWidgets/Sources/`

**Purpose**: Widget and Live Activity implementations

**Key Components**:
- `AlarmExtension.swift` - Widget extension entry point
- `LiveActivity/` - Live Activity implementations for running alarms
- `Widgets/` - Home Screen widget implementations
- `Assets.xcassets` - Widget-specific assets

### Shared Directory
Located in `Shared/`

**Purpose**: Code shared across all targets (not framework)

**Key Components**:
- `AppIntents/` - App Intents for Shortcuts, widgets, and Live Activities
  - `LiveActivity/` - Intents for Live Activity controls (Pause, Resume, Stop, Repeat)
  - `Widget/` - Configuration intents for widgets
  - `ControlWidget/` - Intents for Control Center widgets
  - See `Shared/AppIntents/README.md` for detailed documentation

### External Dependencies

The project uses SPM packages defined in `Tuist/Package.swift`:
- **Gate** (v1.0.0) - Feature flag framework (mayankgandhi/Gate)
- **Telemetry** (v1.0.0) - Analytics framework (mayankgandhi/Telemetry)
- **DesignKit** (v1.0.3) - Design system components (mayankgandhi/DesignKit)
- **Roadmap** (v1.1.0) - Feature roadmap UI (AvdLee/Roadmap)

### App Groups & Entitlements

All targets use the shared app group `group.m.fig` for:
- SwiftData storage shared between app and widgets
- AlarmKit synchronization
- Live Activity data sharing

### Tests
- `Ticker/Tests/TickerTests/` - Unit tests for main app
- `Ticker/Tests/TickerUITests/` - UI automation tests
- `TickerCore/Tests/` - Unit tests for TickerCore framework

## Project Management

This project uses **Tuist** for Xcode project generation. The project has three separate Tuist projects:
- `Project.swift` - Root workspace configuration
- `Ticker/Project.swift` - Main app target configuration
- `TickerCore/Project.swift` - Core framework configuration
- `TickerWidgets/Project.swift` - Widget extension configuration

### Essential Commands

**Generate Xcode Project**
```bash
# From project root - generates workspace with all targets
tuist generate

# Always run after modifying any Project.swift file
```

**Build & Test**
```bash
# Build main app (after tuist generate)
xcodebuild -workspace Ticker.xcworkspace -scheme Ticker build

# Run unit tests
xcodebuild test -workspace Ticker.xcworkspace -scheme Ticker

# Run specific test target
xcodebuild test -workspace Ticker.xcworkspace -scheme TickerTests

# Run UI tests
xcodebuild test -workspace Ticker.xcworkspace -scheme TickerUITests
```

**Development Workflow**
```bash
# Open in Xcode
open Ticker.xcworkspace  # Use workspace, not xcodeproj

# Clean Tuist cache
tuist clean

# Edit Tuist configuration
tuist edit

# Install/update dependencies (after changing Tuist/Package.swift)
tuist install
```

**Important Notes**:
- Always use `Ticker.xcworkspace` (not `Ticker.xcodeproj`) when opening in Xcode
- Run `tuist generate` after modifying any `Project.swift` or `Tuist/Package.swift`
- Dependencies are managed via `Tuist/Package.swift`
- The workspace includes Ticker, TickerCore, and TickerWidgets targets

## Testing

**Run the suite** (the TickerCore scheme holds the alarm tests):

```bash
tuist generate --no-open   # required after any Project.swift change
xcodebuild test -workspace Ticker.xcworkspace -scheme TickerCore \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

Current state: **293 tests, 0 failures**.

**Conventions**
- XCTest, one file per subject, `test_subject_behaviour` or `testSubject_Behaviour` naming
- `FakeAlarmScheduler` (in `TestAlarmFactory.swift`) substitutes for `AlarmManager` via
  `Container.shared.alarmManager.register { ... }`. It can inject `scheduleError`,
  `cancelError` and `scheduleLimit`, which is how the error paths are reachable at all
- `TestAlarmFactory.makeAlarm` builds real `AlarmKit.Alarm` values by round-tripping JSON
  through `Codable` — `Alarm` has no public initializer
- `TestModelContextFactory` gives an in-memory `ModelContext`
- Tests touching `AlarmOccurrenceLog`, `AlarmReactionRecorder` or `AlarmScheduleMigration`
  write to the **shared App Group defaults**, which are process-global. Clear their keys in
  `setUp` and `tearDown` or they leak between tests
- Inject a fixed clock rather than reading wall time. A wall-time test in
  `TickerConfigurationParserTests` passed all day and failed only between 22:00 and midnight

**Expectations**
- New function → a test. Bug fix → a regression test. New error path → a test that triggers it
- New conditional → tests for both branches
- Never commit code that makes existing tests fail

**Not unit-testable — needs a real device** (`/ios-qa`): the five `LiveActivityIntent`s run in
a short-lived process no unit test can host, and AlarmKit draws its own system alert. Live
Activity rendering, Dynamic Island layout, and the weekday upgrade's double-alert behaviour
all have to be verified on hardware.

## SwiftData Usage

The app uses SwiftData for persistent alarm storage:
- Primary model: `Ticker` (defined in `TickerCore/Sources/TickerCore/Models/Ticker.swift`)
- Models use the `@Model` macro
- The `ModelContainer` comes from `TickerSchema.makeSharedContainer()`, called in `Ticker/Sources/App/figApp.swift`
- Schema: **always** `TickerSchema.current` — never construct `Schema([...])` directly. Three processes (app, widget, intents) open one store, and whichever opens first after an update decides how it migrates
- Opening the store returns an error rather than trapping. A `fatalError` here is a launch crash loop whose only remedy is deleting the app, which takes every alarm with it
- Shared app group storage at `group.m.fig` container for cross-target access
- Views access data using `@Query` for fetching and `@Environment(\.modelContext)` for mutations
- AlarmKit integration via `generatedAlarmKitIDs` property for bidirectional sync

**Storage Location**: SwiftData container is shared via app group `group.m.fig` allowing both the main app and widget extension to access the same data.

## AlarmKit Integration

The app integrates with iOS AlarmKit framework for system-level alarm functionality:
- `Ticker` models (in TickerCore) convert to `Alarm` configurations via extensions
- AlarmKit provides system-level alarm scheduling and notifications
- Supports:
  - One-time and recurring (daily) alarms
  - Pre-alert countdowns
  - Post-alert behaviors (snooze, repeat, custom actions)
  - Live Activities during alarm execution
  - Custom presentation with tint colors and secondary buttons
  - Background task scheduling (`com.fig.alarm.regeneration`)

**Permission**: App requires `NSAlarmKitUsageDescription` in Info.plist

## Liquid Glass Design System

### Overview
Liquid Glass is Apple's dynamic material introduced in iOS 26/macOS 26 that combines optical properties of glass with fluidity. It blurs content behind it, reflects surrounding color and light, and reacts to touch/pointer interactions in real time.

### Core Principles
1. **Hierarchy**: Content-first interfaces that prioritize clarity
2. **Dynamism**: Responsive interaction design with fluid motion
3. **Consistency**: Unified design language across Apple platforms

### Material Variants
- **Regular**: Standard implementation, adaptive to context (default)
- **Clear**: More transparent, used sparingly over media-rich content

### API Modifiers

#### Basic Application
```swift
// Default: Regular variant with Capsule shape
Text("Hello, World!")
    .padding()
    .glassEffect()

// Custom shape
Text("Hello, World!")
    .padding()
    .glassEffect(in: .rect(cornerRadius: 16.0))

// Tinted and interactive
Text("Hello, World!")
    .padding()
    .glassEffect(.regular.tint(.orange).interactive())
```

#### Configuration Options
- **Shapes**: Customize with `.rect(cornerRadius:)`, `Circle`, `Capsule`, etc.
- **Tint**: Use `.tint(.color)` for prominent/primary actions
- **Interactive**: Add `.interactive()` for touch/pointer reactions on custom controls

### Combining Multiple Views

#### GlassEffectContainer
Use when applying effects to multiple views for:
- Best rendering performance
- Shape blending between adjacent views
- Morphing animations during transitions

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80, height: 80)
            .glassEffect()

        Image(systemName: "eraser.fill")
            .frame(width: 80, height: 80)
            .glassEffect()
    }
}
```

**Spacing Behavior**:
- Larger spacing = earlier blending of glass effects
- When container spacing > layout spacing, effects blend at rest
- Animating views creates morphing apart/together effects

#### Glass Effect Union
Combine multiple views into single unified glass capsule:

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 20.0) {
    ForEach(items) { item in
        Image(systemName: item.symbol)
            .glassEffect()
            .glassEffectUnion(id: item.groupID, namespace: namespace)
    }
}
```

### Morphing Transitions

Coordinate transitions between views with effects using IDs:

```swift
@State private var isExpanded = false
@Namespace private var namespace

GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80, height: 80)
            .glassEffect()
            .glassEffectID("pencil", in: namespace)

        if isExpanded {
            Image(systemName: "eraser.fill")
                .frame(width: 80, height: 80)
                .glassEffect()
                .glassEffectID("eraser", in: namespace)
        }
    }
}

Button("Toggle") {
    withAnimation {
        isExpanded.toggle()
    }
}
```

**Transition Types**:
- **matchedGeometry** (default): For views within container spacing, creates smooth morphing
- **materialize**: For views farther apart than container spacing, simpler transition
- Use `GlassEffectTransition` to specify custom transitions

### Design Guidelines

#### DO
✅ Apply `.glassEffect()` AFTER other appearance modifiers
✅ Use tinting strategically for primary actions only
✅ Use `GlassEffectContainer` when multiple views have effects
✅ Match container spacing with layout spacing for controlled blending
✅ Use `.interactive()` on custom controls/interactive elements
✅ Limit number of effects onscreen simultaneously for performance

#### DON'T
❌ Stack Glass-on-Glass (glass cannot sample other glass)
❌ Use in scrollable content areas
❌ Create too many `GlassEffectContainer` instances
❌ Apply effects to views outside containers excessively
❌ Use `.glassEffect()` before other modifiers that affect appearance

### Interface Element Behaviors
- Navigation bars float above content
- Tab bars intelligently collapse during scrolling
- Sheets transition with glass effect backgrounds
- Toolbars adapt to environmental conditions
- Controls adopt capsule shapes with improved tap areas

### Accessibility Integration
- Automatically supports reduced transparency
- Provides increased contrast options
- Reduces motion effects when needed
- No special handling required

### Performance Optimization
- Limit simultaneous Liquid Glass effects onscreen
- Use `GlassEffectContainer` to group related effects
- Profile with Instruments: "Explore UI animation hitches and the render loop"
- Monitor rendering performance with "Optimize SwiftUI performance with Instruments"

### Migration Path
For iOS 26/macOS 26:
- **No code changes required** for standard SwiftUI/UIKit/AppKit components
- Simply recompile with iOS 26+ SDK
- Custom components: Add `.glassEffect()` modifier where appropriate

### Example: Custom Button with Liquid Glass
```swift
struct GlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .glassEffect(.regular.interactive())
    }
}
```

### References
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass)
- [Glass API Reference](https://developer.apple.com/documentation/swiftui/glass)

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
