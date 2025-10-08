# Ticker Design System - Implementation Guide

## Quick Start

### 1. Import the Design System

```swift
import SwiftUI

// In any view file
@Environment(\.colorScheme) var colorScheme

// Use design system
Text("6:30")
    .font(TickerTypography.timeHero)
    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
```

### 2. Use Pre-built Modifiers

```swift
// Primary button
Button("Set Alarm") {
    // Action
}
.tickerPrimaryButton()

// Status badge
Text("SCHEDULED")
    .tickerStatusBadge(color: TickerColors.scheduled)

// Card container
VStack {
    // Content
}
.tickerCard()
```

---

## Component Examples

### Primary Action Button

```swift
struct SetAlarmButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            TickerHaptics.criticalAction()
            action()
        }) {
            Text("SET ALARM")
                .frame(maxWidth: .infinity)
        }
        .tickerPrimaryButton()
        .padding(.horizontal, TickerSpacing.md)
    }
}
```

**Usage**:
```swift
SetAlarmButton {
    // Save alarm logic
}
```

---

### Status Badge Component

```swift
struct AlarmStatusBadge: View {
    let state: AlarmState

    private var badgeColor: Color {
        switch state {
        case .scheduled: return TickerColors.scheduled
        case .running: return TickerColors.running
        case .paused: return TickerColors.paused
        case .alerting: return TickerColors.alertActive
        }
    }

    private var badgeText: String {
        switch state {
        case .scheduled: return "SCHEDULED"
        case .running: return "RUNNING"
        case .paused: return "PAUSED"
        case .alerting: return "ALERTING"
        }
    }

    var body: some View {
        Text(badgeText)
            .tickerStatusBadge(color: badgeColor)
    }
}
```

**Usage**:
```swift
AlarmStatusBadge(state: .scheduled)
```

---

### Time Display Component

```swift
struct TimeDisplay: View {
    let time: Date
    let size: TimeDisplaySize

    enum TimeDisplaySize {
        case hero, large, medium

        var font: Font {
            switch self {
            case .hero: return TickerTypography.timeHero
            case .large: return TickerTypography.timeLarge
            case .medium: return TickerTypography.timeMedium
            }
        }
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(time, style: .time)
            .font(size.font)
            .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
            .monospacedDigit()
    }
}
```

**Usage**:
```swift
TimeDisplay(time: alarm.time, size: .hero)
TimeDisplay(time: alarm.time, size: .large)  // In list
```

---

### Alarm Cell (Redesigned)

```swift
struct TickerAlarmCell: View {
    let alarm: AlarmItem
    @Environment(\.colorScheme) var colorScheme
    @Environment(AlarmService.self) private var alarmService

    var body: some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon
            categoryIcon

            // Content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(alarm.displayName)
                    .font(TickerTypography.headerSmall)
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                scheduleInfo
                    .font(TickerTypography.bodySmall)
                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }

            Spacer()

            // Time + Status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                timeDisplay

                AlarmStatusBadge(state: alarmState)
            }
        }
        .padding(TickerSpacing.md)
        .frame(minHeight: TickerSpacing.tapTargetPreferred)
        .tickerCard()
        .contentShape(Rectangle())
        .onTapGesture {
            TickerHaptics.standardAction()
            // Navigate to detail
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 48, height: 48)

            Image(systemName: alarm.tickerData?.icon ?? TickerIcons.alarmScheduled)
                .font(.system(size: 24))
                .foregroundStyle(categoryColor)
        }
    }

    private var timeDisplay: some View {
        Group {
            if let schedule = alarm.schedule {
                switch schedule {
                case .oneTime(let date):
                    Text(date, style: .time)
                case .daily(let time):
                    Text(formatTime(time))
                }
            } else {
                Text("--:--")
            }
        }
        .font(TickerTypography.timeLarge)
        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
        .monospacedDigit()
    }

    private var scheduleInfo: some View {
        Group {
            if let schedule = alarm.schedule {
                HStack(spacing: 4) {
                    Image(systemName: scheduleIcon(for: schedule))
                    Text(scheduleDescription(for: schedule))
                }
            }
        }
    }

    private var categoryColor: Color {
        if let hex = alarm.tickerData?.colorHex,
           let color = hexToColor(hex) {
            return color
        }
        return TickerColors.criticalRed
    }

    private var alarmState: AlarmState {
        alarmService.getAlarmState(id: alarm.id)?.state ?? .scheduled
    }

    // Helper methods...
}
```

---

### Empty State

```swift
struct TickerEmptyState: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.xl) {
            Spacer()

            Image(systemName: TickerIcons.alarmScheduled)
                .font(.system(size: 128))
                .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

            VStack(spacing: TickerSpacing.xs) {
                Text("No Active Alarms")
                    .font(TickerTypography.headerLarge)
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                Text("Tap + to create one")
                    .font(TickerTypography.bodyMedium)
                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }

            Button(action: {
                TickerHaptics.criticalAction()
                action()
            }) {
                Text("ADD ALARM")
                    .frame(maxWidth: .infinity)
            }
            .tickerPrimaryButton()
            .padding(.horizontal, TickerSpacing.xxl)

            Spacer()
        }
    }
}
```

---

### Pulsing Alert Indicator

```swift
struct PulsingAlertIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: TickerSpacing.sm) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(TickerColors.alertActive)
                    .frame(width: 12, height: 12)
                    .opacity(isPulsing ? 0.3 : 1.0)
                    .animation(
                        TickerAnimation.pulse
                            .delay(Double(index) * 0.2),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}
```

**Usage**: When alarm is actively alerting
```swift
if alarm.state == .alerting {
    PulsingAlertIndicator()
}
```

---

## Screen Templates

### Alarm List Screen

```swift
struct AlarmListView: View {
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

    private var displayAlarms: [(state: AlarmState, metadata: AlarmItem?)] {
        alarmService.getAlarmsWithMetadata(context: modelContext)
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayAlarms.isEmpty {
                    TickerEmptyState {
                        showAddSheet = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: TickerSpacing.md) {
                            ForEach(displayAlarms, id: \.state.id) { item in
                                if let metadata = item.metadata {
                                    TickerAlarmCell(alarm: metadata)
                                }
                            }
                        }
                        .padding(TickerSpacing.md)
                    }
                }
            }
            .navigationTitle("ALARMS")
            .font(TickerTypography.headerXL)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        TickerHaptics.standardAction()
                        showAddSheet = true
                    } label: {
                        Image(systemName: TickerIcons.add)
                            .font(.system(size: 24))
                            .foregroundStyle(TickerColors.criticalRed)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AlarmEditorView()
        }
    }
}
```

---

### Alarm Detail Screen

```swift
struct AlarmDetailView: View {
    let alarm: AlarmItem
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.xl) {
            // Header
            HStack {
                Button {
                    TickerHaptics.standardAction()
                    dismiss()
                } label: {
                    Image(systemName: TickerIcons.close)
                        .font(.system(size: 24))
                }
                Spacer()
            }
            .padding(TickerSpacing.md)

            Spacer()

            // Hero Time
            TimeDisplay(time: alarm.nextOccurrence, size: .hero)

            // Label
            Text(alarm.displayName)
                .font(TickerTypography.headerLarge)
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

            // Details
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                DetailRow(icon: "calendar", text: scheduleText)
                DetailRow(icon: "bell", text: "Default sound")
                DetailRow(icon: "iphone.radiowaves.left.and.right", text: "Vibrate on")
            }
            .padding(TickerSpacing.md)

            // Status
            AlarmStatusBadge(state: .scheduled)
                .padding(TickerSpacing.md)

            Spacer()

            // Actions
            VStack(spacing: TickerSpacing.md) {
                Button {
                    TickerHaptics.criticalAction()
                    // Disable alarm
                } label: {
                    Text("DISABLE ALARM")
                        .frame(maxWidth: .infinity)
                }
                .tickerPrimaryButton()

                Button {
                    TickerHaptics.standardAction()
                    // Edit
                } label: {
                    Text("Edit Details")
                }
                .tickerSecondaryButton()
            }
            .padding(TickerSpacing.md)
        }
    }
}
```

---

## Common Patterns

### Loading State

```swift
struct LoadingIndicator: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(
                tint: TickerColors.criticalRed
            ))
            .scaleEffect(1.5)
    }
}
```

### Destructive Confirmation

```swift
.alert("Delete Alarm?", isPresented: $showDeleteAlert) {
    Button("Cancel", role: .cancel) {
        TickerHaptics.standardAction()
    }
    Button("Delete", role: .destructive) {
        TickerHaptics.error()
        // Delete
    }
} message: {
    Text("This alarm will be permanently deleted.")
}
```

### Haptic Patterns

```swift
// Button tap
.onTapGesture {
    TickerHaptics.standardAction()  // Medium impact
    // Action
}

// Toggle switch
.onChange(of: isEnabled) { _, newValue in
    TickerHaptics.selection()
    // Update
}

// Critical action
Button("Set Alarm") {
    TickerHaptics.criticalAction()  // Heavy impact
    // Save
}

// Success
.onAppear {
    TickerHaptics.success()  // Notification success
}

// Error
.onAppear {
    TickerHaptics.error()  // Notification error
}
```

---

## Migration Checklist

### Replace Old Components

1. **Buttons**
   ```swift
   // Old
   Button("Save") { }
       .buttonStyle(.borderedProminent)

   // New
   Button("SAVE") { }
       .tickerPrimaryButton()
   ```

2. **Colors**
   ```swift
   // Old
   .foregroundStyle(.blue)

   // New
   .foregroundStyle(TickerColors.scheduled)
   ```

3. **Typography**
   ```swift
   // Old
   .font(.system(size: 56, weight: .bold))

   // New
   .font(TickerTypography.timeLarge)
   ```

4. **Spacing**
   ```swift
   // Old
   .padding(16)

   // New
   .padding(TickerSpacing.md)
   ```

---

## Testing the Design System

### Visual Regression

```swift
#Preview("Light Mode") {
    TickerAlarmCell(alarm: sampleAlarm)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    TickerAlarmCell(alarm: sampleAlarm)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility Large Text") {
    TickerAlarmCell(alarm: sampleAlarm)
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}
```

### Contrast Testing

Use Xcode's Accessibility Inspector:
1. Product > Analyze > Accessibility
2. Check all color ratios >= 4.5:1 (AA) or 7:1 (AAA)
3. Verify tap target sizes >= 44x44pt

---

## Performance Notes

### Optimization Tips

1. **Use LazyVStack for lists**
   ```swift
   ScrollView {
       LazyVStack {
           ForEach(alarms) { alarm in
               TickerAlarmCell(alarm: alarm)
           }
       }
   }
   ```

2. **Cache color conversions**
   ```swift
   private static var colorCache: [String: Color] = [:]
   ```

3. **Minimize animations**
   - Only pulse when actively alerting
   - Use `.animation(.none)` to disable unwanted animations

4. **Optimize haptics**
   - Don't trigger haptics in rapid succession
   - Debounce user interactions

---

## Common Issues

### Issue: Colors not updating in dark mode
**Solution**: Ensure using `@Environment(\.colorScheme)`
```swift
@Environment(\.colorScheme) var colorScheme
// Use: TickerColors.textPrimary(for: colorScheme)
```

### Issue: Buttons too small on older devices
**Solution**: Use minimum tap target
```swift
.frame(minHeight: TickerSpacing.tapTargetMin)
```

### Issue: Text truncating
**Solution**: Use appropriate line limits
```swift
.lineLimit(2)
.minimumScaleFactor(0.8)
```

---

**Implementation Guide Version**: 1.0
**Last Updated**: October 2025
