# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Ticker** (formerly "fig") is a SwiftUI iOS/iPadOS alarm application using SwiftData for persistence and AlarmKit for system alarm integration. The app features Live Activities, widgets, control center integration, and follows modern iOS 26+ Liquid Glass design patterns.

**Product Name**: Super Alarm - Ticker
**Bundle ID**: m.fig
**Deployment Target**: iOS 26.0+
**Build System**: Tuist (for project generation)

## Architecture

### Core Structure
- **App Entry Point**: `fig/App/figApp.swift` - Defines the main app structure, sets up SwiftData `ModelContainer` with `Ticker` model, and initializes `AlarmService`
- **Main View**: `fig/App/AppView.swift` - Root view coordinating navigation and primary UI
- **Data Models**:
  - `fig/Models/AlarmItem.swift` - Core `Ticker` SwiftData model with schedule, countdown, and presentation configuration
  - `Shared/AlarmMetadata.swift` - Shared data structures for alarm state synchronization
- **Services**:
  - `fig/Services/AlarmService.swift` - Main service coordinating alarm operations
  - `fig/Services/AlarmStateManager.swift` - Manages alarm state and lifecycle
  - `fig/Services/AlarmSyncCoordinator.swift` - Synchronizes alarms with AlarmKit
  - `fig/Services/AlarmConfigurationBuilder.swift` - Builds AlarmKit configurations from Ticker models

### Key Views
- `fig/App/ContentView.swift` - Main alarm list interface
- `fig/App/AddTickerView/` - Add/edit alarm flow with modular components
- `fig/App/TodayClockView/` - Today view showing clock and upcoming alarms
- `fig/App/AlarmDetailView.swift` - Detailed alarm view
- `fig/AlarmCell.swift` - Alarm list cell component
- `fig/Settings/SettingsView.swift` - Settings interface

### App Extensions
- `alarm/` - Widget and Live Activity extension bundle
  - `alarm/alarm.swift` - Widget implementations
  - `alarm/alarmControl.swift` - Control Center widget
  - `alarm/AlarmLiveActivity.swift` - Live Activity for running alarms
- `fig/AppIntents/` - App Intents for Shortcuts and widget interactivity

### Design System
- `fig/DesignSystem/TickerDesignSystem.swift` - Centralized design tokens and Liquid Glass components
- `fig/DesignSystem/TickerDesignSystemPreviews.swift` - SwiftUI previews for design system
- `fig/Extensions/` - Font, color, and UI extensions

### Tests
- `figTests/` - Unit tests including `AlarmServiceTests.swift`
- `figUITests/` - UI automation tests

## Project Management

This project uses **Tuist** for Xcode project generation:

### Tuist Commands
```bash
# Generate Xcode project from Project.swift
tuist generate

# Clean generated files
tuist clean

# Edit project configuration
tuist edit
```

### Build Commands
```bash
# Build with xcodebuild (after tuist generate)
xcodebuild -project Ticker.xcodeproj -scheme Ticker build

# Run tests
xcodebuild test -project Ticker.xcodeproj -scheme Ticker

# Open in Xcode
open Ticker.xcodeproj
```

**Important**: Always run `tuist generate` after modifying `Project.swift` to regenerate the Xcode project.

## SwiftData Usage

The app uses SwiftData for persistent alarm storage:
- Primary model: `Ticker` (defined in `fig/Models/AlarmItem.swift`)
- Models use the `@Model` macro
- The `ModelContainer` is configured in `figApp.swift` with persistent storage (not in-memory)
- Schema: `Schema([Ticker.self])`
- Views access data using `@Query` for fetching and `@Environment(\.modelContext)` for mutations
- AlarmKit integration via `generatedAlarmKitIDs` property for bidirectional sync

## AlarmKit Integration

The app integrates with iOS AlarmKit framework for system-level alarm functionality:
- `Ticker` models convert to `Alarm` configurations via extensions
- `AlarmService` manages the bridge between SwiftData and AlarmKit
- Supports:
  - One-time and recurring (daily) alarms
  - Pre-alert countdowns
  - Post-alert behaviors (snooze, repeat, custom actions)
  - Live Activities during alarm execution
  - Custom presentation with tint colors and secondary buttons

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
