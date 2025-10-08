# AppIntents Documentation

This directory contains all AppIntent implementations for the Fig alarm application. AppIntents enable integration with system features like Live Activities, Dynamic Island, Widgets, and Control Center.

## Directory Structure

```
AppIntents/
├── README.md (this file)
├── LiveActivity/       # Intents for Live Activities and Dynamic Island
├── Widget/             # Intents for Home Screen widgets
└── ControlWidget/      # Intents for Control Center widgets
```

---

## LiveActivity Intents

Located in `LiveActivity/`, these intents control alarm behavior from Live Activities and the Dynamic Island.

### PauseIntent

**File:** `LiveActivity/PauseIntent.swift`

**Purpose:** Pauses a running countdown alarm

**Parameters:**
- `alarmID: String` - The UUID of the alarm to pause

**Usage:**
```swift
let intent = PauseIntent(alarmID: alarm.id.uuidString)
// Used in Live Activity buttons to pause countdown
```

**Integration Points:**
- Live Activity countdown view (`AlarmLiveActivity.swift:169`)
- Pause button in Dynamic Island
- Pause button on Lock Screen

---

### StopIntent

**File:** `LiveActivity/StopIntent.swift`

**Purpose:** Stops an active alarm and dismisses the Live Activity

**Parameters:**
- `alarmID: String` - The UUID of the alarm to stop

**Usage:**
```swift
let intent = StopIntent(alarmID: alarm.id.uuidString)
// Used as the primary action button in alerts
```

**Integration Points:**
- Live Activity alert view (`AlarmLiveActivity.swift:176`)
- Stop button in all Live Activity states
- Primary dismiss action

---

### RepeatIntent

**File:** `LiveActivity/RepeatIntent.swift`

**Purpose:** Restarts a countdown alarm from the beginning

**Parameters:**
- `alarmID: String` - The UUID of the alarm to repeat

**Usage:**
```swift
let intent = RepeatIntent(alarmID: alarm.id.uuidString)
// Used when secondary button behavior is .countdown
```

**Integration Points:**
- Secondary button in alert presentations (`ViewModel.swift:81`)
- Repeat action after countdown completes
- Used when `secondaryButtonBehavior = .countdown`

---

### ResumeIntent

**File:** `LiveActivity/ResumeIntent.swift`

**Purpose:** Resumes a paused countdown alarm

**Parameters:**
- `alarmID: String` - The UUID of the alarm to resume

**Usage:**
```swift
let intent = ResumeIntent(alarmID: alarm.id.uuidString)
// Used in paused state to restart countdown
```

**Integration Points:**
- Live Activity paused view (`AlarmLiveActivity.swift:171`)
- Resume button when alarm is paused
- Restores countdown from remaining time

---

### OpenAlarmAppIntent

**File:** `LiveActivity/OpenAlarmAppIntent.swift`

**Purpose:** Opens the main app and stops the current alarm

**Parameters:**
- `alarmID: String` - The UUID of the alarm

**Properties:**
- `openAppWhenRun = true` - Automatically launches the app

**Usage:**
```swift
let intent = OpenAlarmAppIntent(alarmID: alarm.id.uuidString)
// Used as custom secondary button to open app
```

**Integration Points:**
- Custom secondary button (`ViewModel.swift:100`)
- Used when `secondaryButtonBehavior = .custom`
- Provides deep link into app

---

## Widget Intents

Located in `Widget/`, these intents configure Home Screen widgets.

### ConfigurationAppIntent

**File:** `Widget/ConfigurationAppIntent.swift`

**Purpose:** Provides configurable parameters for the alarm widget

**Type:** `WidgetConfigurationIntent`

**Parameters:**
- `favoriteEmoji: String` - User's chosen emoji (default: "😃")

**Usage:**
```swift
struct Provider: AppIntentTimelineProvider {
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Use configuration.favoriteEmoji in widget
    }
}
```

**Integration Points:**
- Widget timeline provider (`alarm/alarm.swift`)
- AppIntentConfiguration setup
- Widget customization UI

---

## Control Widget Intents

Located in `ControlWidget/`, these intents enable Control Center integration.

### TimerConfiguration

**File:** `ControlWidget/TimerConfiguration.swift`

**Purpose:** Configuration for the timer control widget

**Type:** `ControlConfigurationIntent`

**Parameters:**
- `timerName: String` - Name of the timer (default: "Timer")

**Usage:**
```swift
AppIntentControlConfiguration(
    kind: Self.kind,
    provider: Provider()
) { value in
    // Control widget UI using configuration
}
```

**Integration Points:**
- Control widget provider (`alarm/alarmControl.swift`)
- Control Center customization

---

### StartTimerIntent

**File:** `ControlWidget/StartTimerIntent.swift`

**Purpose:** Starts or stops a timer from the Control Center

**Type:** `SetValueIntent`

**Parameters:**
- `name: String` - The timer name
- `value: Bool` - Whether the timer should be running

**Usage:**
```swift
ControlWidgetToggle(
    "Start Timer",
    isOn: value.isRunning,
    action: StartTimerIntent(value.name)
)
```

**Integration Points:**
- Control widget toggle (`alarm/alarmControl.swift:23`)
- Control Center timer controls
- Toggle between start/stop states

---

## Architecture Overview

### How AppIntents Work in This App

1. **Live Activities** use `LiveActivityIntent` conforming types to provide interactive controls
2. **Widgets** use `WidgetConfigurationIntent` for user-configurable parameters
3. **Control Widgets** use `ControlConfigurationIntent` and `SetValueIntent` for toggle controls

### Intent Flow

```
User Interaction (Live Activity/Widget/Control)
    ↓
AppIntent perform() method
    ↓
AlarmManager.shared methods
    ↓
System state updated
    ↓
Live Activity/Widget updates automatically
```

### Key Design Patterns

1. **All intents accept `alarmID` as String** - Converted to UUID internally for type safety
2. **All intents provide both empty and parameterized initializers** - Required by AppIntents framework
3. **Intents are stateless** - All state managed by `AlarmManager.shared`
4. **Intent conformance** determines capabilities:
   - `LiveActivityIntent` - Interactive Live Activity buttons
   - `WidgetConfigurationIntent` - Widget customization
   - `SetValueIntent` - Toggle controls

---

## Adding New Intents

### For Live Activities

1. Create new file in `LiveActivity/`
2. Conform to `LiveActivityIntent`
3. Implement `perform()` method
4. Add localized title and description
5. Define parameters with `@Parameter`
6. Update `AlarmManager` if new functionality needed
7. Wire into `AlarmLiveActivity.swift` views

### For Widgets

1. Create new file in `Widget/`
2. Conform to `WidgetConfigurationIntent`
3. Define parameters for widget customization
4. Update widget provider to use new configuration

### For Control Widgets

1. Create new files in `ControlWidget/`
2. Create configuration intent (`ControlConfigurationIntent`)
3. Create action intent (`SetValueIntent` or `AppIntent`)
4. Update control widget configuration

---

## Related Files

- **AlarmManager** (`AlarmKit` framework) - Backend service handling all alarm operations
- **ViewModel.swift** (`fig/ViewModel.swift`) - Creates and configures intents for scheduling
- **AlarmLiveActivity** (`alarm/AlarmLiveActivity 2.swift`) - Live Activity UI using the intents
- **alarm.swift** (`alarm/alarm.swift`) - Widget using ConfigurationAppIntent
- **alarmControl.swift** (`alarm/alarmControl.swift`) - Control widget using timer intents

---

## Testing Intents

### Live Activity Intents
1. Schedule an alarm with countdown
2. Verify pause/resume buttons work
3. Test stop button dismisses activity
4. Verify repeat restarts countdown
5. Test custom "Open App" button

### Widget Intent
1. Add widget to Home Screen
2. Long press to configure
3. Verify emoji parameter updates widget

### Control Widget Intent
1. Add control to Control Center
2. Toggle timer on/off
3. Verify state updates correctly

---

## Common Issues

### Intent Not Found
- Ensure file is added to the correct target
- Check import statements in using files
- Verify intent is `public` or `internal` (not `private`)

### Parameter Not Working
- Verify `@Parameter` attribute is present
- Check default values are provided
- Ensure parameter types are supported by AppIntents

### Intent Doesn't Execute
- Check `AlarmManager.shared` is accessible
- Verify UUID conversion from String succeeds
- Add error handling in `perform()` method

---

## Additional Resources

- [Apple AppIntents Documentation](https://developer.apple.com/documentation/appintents)
- [Live Activities Programming Guide](https://developer.apple.com/documentation/activitykit)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

---

**Last Updated:** October 2025
**Maintained By:** Fig Development Team
