# Debug View Guide

## Overview

The AITickerGenerator Debug View now shows **detailed values** for all parsed data during streaming, making it easy to understand exactly what the AI is generating in real-time.

## How to Access

1. Open the Natural Language view (sparkles button on main screen)
2. Tap the **terminal icon** (📟) in the top-right toolbar
3. The debug panel appears below the option pills

## Enhanced Debug Logging

### 1. Parse Start Event

Shows the initial input and token estimation:

```
🔍 19:45:12.345  Starting parse
    • input: "Wake up at 7am every weekday"
    • length: 30 chars
    • tokens: ~8
```

### 2. Progressive Streaming Updates

Shows **actual parsed values** as they become available:

```
🔄 19:45:12.678  Progressive update #1
    • fields: label, hour
    • label: "Wake Up"
    • hour: 7

🔄 19:45:12.789  Progressive update #2
    • fields: label, hour, minute, repeat
    • label: "Wake Up"
    • hour: 7
    • minute: 0
    • repeat: weekdays

🔄 19:45:12.890  Progressive update #3
    • fields: label, hour, minute, repeat, icon
    • label: "Wake Up"
    • hour: 7
    • minute: 0
    • repeat: weekdays
    • icon: sunrise.fill

🔄 19:45:13.001  Progressive update #4
    • fields: label, hour, minute, repeat, icon, color
    • label: "Wake Up"
    • hour: 7
    • minute: 0
    • repeat: weekdays
    • icon: sunrise.fill
    • color: #FF9F1C
```

### 3. Streaming Complete

Performance metrics:

```
⏱️ 19:45:13.125  Streaming completed
    • duration: 0.78
    • updates: 4
```

### 4. Final Configuration

Complete parsed configuration:

```
✅ 19:45:13.234  Configuration generated
    • label: "Wake Up"
    • time: 07:00
    • icon: sunrise.fill
    • color: #FF9F1C
    • repeat: weekdays(5)
```

## Example: Complex Input with Countdown

**Input:** `"Take medication at 9am and 9pm daily with 1 hour countdown"`

**Debug Log:**

```
🔍 19:46:00.123  Starting parse
    • input: "Take medication at 9am and 9pm daily with 1 hour countdown"
    • length: 58 chars
    • tokens: ~15

🔄 19:46:00.456  Progressive update #1
    • fields: label, hour, minute
    • label: "Take Medication"
    • hour: 9
    • minute: 0

🔄 19:46:00.567  Progressive update #2
    • fields: label, hour, minute, repeat
    • label: "Take Medication"
    • hour: 9
    • minute: 0
    • repeat: daily

🔄 19:46:00.678  Progressive update #3
    • fields: label, hour, minute, repeat, icon
    • label: "Take Medication"
    • hour: 9
    • minute: 0
    • repeat: daily
    • icon: pills.fill

🔄 19:46:00.789  Progressive update #4
    • fields: label, hour, minute, repeat, icon, color
    • label: "Take Medication"
    • hour: 9
    • minute: 0
    • repeat: daily
    • icon: pills.fill
    • color: #4ECDC4
    • countdownH: 1h
    • countdownM: 0m

⏱️ 19:46:00.890  Streaming completed
    • duration: 0.43
    • updates: 4

✅ 19:46:00.912  Configuration generated
    • label: "Take Medication"
    • time: 09:00
    • icon: pills.fill
    • color: #4ECDC4
    • repeat: daily
    • countdown: 1h 0m
```

## Example: Specific Days Pattern

**Input:** `"Gym on Monday Wednesday Friday at 6pm"`

**Debug Log:**

```
🔍 19:47:00.123  Starting parse
    • input: "Gym on Monday Wednesday Friday at 6pm"
    • length: 38 chars
    • tokens: ~10

🔄 19:47:00.456  Progressive update #1
    • fields: label, hour, minute, repeat
    • label: "Gym"
    • hour: 18
    • minute: 0
    • repeat: specificDays
    • repeatDays: Monday,Wednesday,Friday

🔄 19:47:00.567  Progressive update #2
    • fields: label, hour, minute, repeat, icon, color
    • label: "Gym"
    • hour: 18
    • minute: 0
    • repeat: specificDays
    • repeatDays: Monday,Wednesday,Friday
    • icon: dumbbell.fill
    • color: #E63946

⏱️ 19:47:00.678  Streaming completed
    • duration: 0.22
    • updates: 2

✅ 19:47:00.701  Configuration generated
    • label: "Gym"
    • time: 18:00
    • icon: dumbbell.fill
    • color: #E63946
    • repeat: weekdays(3)
```

## Example: One-Time with Date

**Input:** `"Meeting next Tuesday at 2:30pm"`

**Debug Log:**

```
🔍 19:48:00.123  Starting parse
    • input: "Meeting next Tuesday at 2:30pm"
    • length: 31 chars
    • tokens: ~8

🔄 19:48:00.456  Progressive update #1
    • fields: label, hour, minute
    • label: "Meeting"
    • hour: 14
    • minute: 30

🔄 19:48:00.567  Progressive update #2
    • fields: label, hour, minute, repeat
    • label: "Meeting"
    • hour: 14
    • minute: 30
    • repeat: oneTime
    • year: 2025
    • month: 10
    • day: 29

🔄 19:48:00.678  Progressive update #3
    • fields: label, hour, minute, repeat, icon, color
    • label: "Meeting"
    • hour: 14
    • minute: 30
    • repeat: oneTime
    • year: 2025
    • month: 10
    • day: 29
    • icon: person.2.fill
    • color: #4A5899

⏱️ 19:48:00.789  Streaming completed
    • duration: 0.33
    • updates: 3

✅ 19:48:00.812  Configuration generated
    • label: "Meeting"
    • time: 14:30
    • icon: person.2.fill
    • color: #4A5899
    • repeat: oneTime
```

## All Available Metadata Fields

### Parse Start
- `input` - The actual text being parsed
- `length` - Character count
- `tokens` - Estimated token count (~)

### Streaming Updates
- `fields` - Comma-separated list of available fields
- `label` - Activity description (quoted)
- `hour` - Hour in 24-hour format
- `minute` - Minute
- `repeat` - Repeat pattern (oneTime, daily, weekdays, specificDays)
- `repeatDays` - Comma-separated weekday names (for specificDays)
- `icon` - SF Symbol name
- `color` - Hex color with # prefix
- `countdownH` - Countdown hours with "h" suffix
- `countdownM` - Countdown minutes with "m" suffix
- `year` - Year (if explicitly mentioned)
- `month` - Month (if explicitly mentioned)
- `day` - Day (if explicitly mentioned)

### Streaming Complete
- `duration` - Total streaming time in seconds
- `updates` - Number of UI updates performed

### Final Configuration
- `label` - Final activity label (quoted)
- `time` - Formatted time (HH:MM)
- `icon` - SF Symbol name
- `color` - Hex color with # prefix
- `repeat` - Repeat pattern with details:
  - `oneTime` - Single occurrence
  - `daily` - Every day
  - `weekdays(N)` - Number of selected weekdays
  - `hourly(N)` - Every N hours
  - `every(N unit)` - Every N units
  - `biweekly(N)` - Biweekly with N days
  - `monthly` - Monthly pattern
  - `yearly(M/D)` - Yearly on month M, day D
- `countdown` - Countdown duration (e.g., "1h 30m")

## Color Coding

Events are color-coded in the debug view:

- **Green background** (✅) - Success events
- **Red background** (❌) - Error events
- **Orange background** (⚠️) - Warning events
- **Purple background** (⏱️) - Timing/performance events
- **Blue background** (🔄) - Streaming progress events
- **Cyan background** (🔍) - Parsing start events
- **Gray background** (ℹ️) - Info events

## Performance Analysis

Use the debug view to:

1. **Monitor latency**: Check time between "Starting parse" and "Streaming completed"
2. **Track streaming efficiency**: Compare number of updates vs duration
3. **Verify throttling**: Updates should be ~100ms apart (10 per second max)
4. **Validate progressive updates**: See how fields become available incrementally
5. **Check final accuracy**: Compare final configuration to intended input

## Tips

- **Scroll the event log**: Recent events appear at the top
- **Clear events**: Tap the trash icon to start fresh
- **Test edge cases**: Try very long inputs, ambiguous times, complex patterns
- **Compare modes**: Note differences when Foundation Models unavailable (falls back to regex)

## Troubleshooting

### No streaming updates appearing
- Check that Foundation Models are available (green status)
- Verify input is > 3 characters
- Wait for debounce delay (500ms)

### Updates too fast/slow
- Check throttle interval (100ms default)
- Review "Streaming completed" metadata for update count

### Missing fields
- Some fields are optional (year/month/day, countdown, repeatDays)
- Only present when explicitly mentioned in input

### Unexpected values
- Compare streaming updates to see when value changed
- Check if defaults are being used (e.g., hour: 12, minute: 0)

---

**Last Updated:** 2025-10-27
**Version:** 2.0 (Enhanced with value logging)
