# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI macOS/iOS application using SwiftData for persistence. The app uses the modern SwiftUI app lifecycle with `@main` and SwiftData's `ModelContainer` for data management.

## Architecture

- **App Entry Point**: `fig/figApp.swift` - Defines the main app structure and sets up the SwiftData `ModelContainer` with the `Item` model
- **Data Models**: `fig/Item.swift` - SwiftData models using the `@Model` macro
- **Views**: `fig/ContentView.swift` - SwiftUI views that use `@Query` to fetch SwiftData objects and `@Environment(\.modelContext)` to access the model context
- **Tests**:
  - `figTests/` - Unit tests
  - `figUITests/` - UI tests

## Common Commands

Build and run the app:
```bash
xcodebuild -project fig.xcodeproj -scheme fig build
```

Run tests:
```bash
xcodebuild test -project fig.xcodeproj -scheme fig
```

Alternatively, open the project in Xcode:
```bash
open fig.xcodeproj
```

## SwiftData Usage

The app uses SwiftData for persistence:
- Models are defined with the `@Model` macro
- The `ModelContainer` is configured in `figApp.swift` with persistent storage (not in-memory)
- Views access data using `@Query` for fetching and `@Environment(\.modelContext)` for mutations
- The schema is registered in the `ModelContainer` initialization

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
