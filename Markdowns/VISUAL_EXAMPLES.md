# Ticker Visual Design Examples

## Screen Mockups (ASCII)

### 1. Alarm List Screen (Primary View)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ALARMS                [+]┃  ← 34pt Black, Critical red button
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│                           │
│  ┌────────────────────┐  │
│  │ ⏰  6:30            │  │  ← 56pt Bold Mono time
│  │     Wake Up        │  │  ← 17pt Semibold label
│  │     Every day      │  │  ← 13pt Regular
│  │              [🔵]   │  │  ← Status badge top right
│  └────────────────────┘  │  88pt height cell
│                           │
│  ┌────────────────────┐  │
│  │ 💪  7:15            │  │
│  │     Gym Time       │  │
│  │     Mon-Fri   [🟢] │  │  ← Running state
│  └────────────────────┘  │
│                           │
│  ┌────────────────────┐  │
│  │ 🍳  8:00            │  │
│  │     Breakfast      │  │
│  │     Paused    [🟡] │  │  ← Paused state
│  └────────────────────┘  │
│                           │
│  ┌────────────────────┐  │
│  │ ⏰  19:30           │  │
│  │     Dinner Prep    │  │
│  │     Once only [🔵] │  │
│  └────────────────────┘  │
│                           │
└───────────────────────────┘
```

**Key Features**:
- Time dominates each cell (56pt)
- Status badge always visible
- Icons use category colors
- Clear visual hierarchy
- Generous tap targets (88pt height)

---

### 2. Alarm Detail Screen (Full)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  [X]                      ┃  ← Close button top-left
┃                           ┃
┃                           ┃
┃        6:30               ┃  ← 72pt Heavy Rounded Mono
┃         AM                ┃     (Hero time display)
┃                           ┃
┃                           ┃
┃      Wake Up Call         ┃  ← 28pt Heavy label
┃                           ┃
┃  📅  Every day            ┃  ← 17pt with icon
┃  🔔  Default sound        ┃
┃  📱  Vibrate on           ┃
┃                           ┃
┃  ┌─────────────────────┐ ┃
┃  │    🔵 SCHEDULED     │ ┃  ← 11pt Heavy uppercase badge
┃  └─────────────────────┘ ┃
┃                           ┃
┃                           ┃
┃  ┏━━━━━━━━━━━━━━━━━━━┓  ┃
┃  ┃  DISABLE ALARM    ┃  ┃  ← 20pt Bold, 64pt height
┃  ┗━━━━━━━━━━━━━━━━━━━┛  ┃     Primary button
┃                           ┃
┃      Edit Details         ┃  ← 17pt Semibold link
┃                           ┃
└───────────────────────────┘
```

**Key Features**:
- Time is the absolute hero
- All info scannable in 2 seconds
- Single primary action (large, red)
- Secondary action as text link
- Status badge highly visible

---

### 3. Active Alarm (Alerting State)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                           ┃
┃                           ┃
┃         🔴 🔴 🔴         ┃  ← Pulsing red circles
┃                           ┃
┃        6:30               ┃  ← 72pt time
┃         AM                ┃
┃                           ┃
┃      Wake Up Call         ┃  ← 28pt Heavy
┃                           ┃
┃  ┌─────────────────────┐ ┃
┃  │   🔴 ALERTING       │ ┃  ← Red badge, pulsing
┃  └─────────────────────┘ ┃
┃                           ┃
┃                           ┃
┃  ┏━━━━━━━━━━━━━━━━━━━┓  ┃
┃  ┃     DISMISS       ┃  ┃  ← Red, 64pt height
┃  ┗━━━━━━━━━━━━━━━━━━━┛  ┃     Continuous haptic
┃                           ┃
┃  ┌───────────────────┐   ┃
┃  │   SNOOZE 5 MIN    │   ┃  ← 48pt secondary
┃  └───────────────────┘   ┃
┃                           ┃
└───────────────────────────┘
```

**Key Features**:
- Pulsing red indicators (animation)
- Alert badge draws eye immediately
- Two clear action buttons
- Haptic feedback continuous
- Impossible to miss or ignore

---

### 4. Empty State

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ALARMS                [+]┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│                           │
│                           │
│                           │
│           ⏰              │  ← 128pt icon, gray
│                           │
│     No Active Alarms      │  ← 28pt Heavy
│                           │
│   Tap + to create one     │  ← 15pt Regular, 70% opacity
│                           │
│                           │
│  ┏━━━━━━━━━━━━━━━━━━━┓  │
│  ┃    ADD ALARM      ┃  │  ← Primary button
│  ┗━━━━━━━━━━━━━━━━━━━┛  │
│                           │
│                           │
│                           │
└───────────────────────────┘
```

**Key Features**:
- Centered, minimal
- Clear call-to-action
- No decorative elements
- Friendly but not playful

---

### 5. Alarm Editor (Time Picker)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  [Cancel]  NEW ALARM [Save]┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│                           │
│  ┌───────────────────┐   │
│  │ Label              │   │
│  │  Wake Up Call     │   │  ← 17pt input field
│  └───────────────────┘   │
│                           │
│  Time                     │  ← 17pt Semibold label
│  ┌───────────────────┐   │
│  │   06  :  30   AM  │   │  ← Picker, 36pt digits
│  │   ▲    ▲      ▲   │   │
│  │   ▼    ▼      ▼   │   │
│  └───────────────────┘   │
│                           │
│  Repeat                   │
│  ┌───────────────────┐   │
│  │  Every day    >   │   │  ← Disclosure
│  └───────────────────┘   │
│                           │
│  Sound                    │
│  ┌───────────────────┐   │
│  │  Default       >  │   │
│  └───────────────────┘   │
│                           │
│  ┏━━━━━━━━━━━━━━━━━━━┓  │
│  ┃   SAVE ALARM      ┃  │  ← Primary action
│  ┗━━━━━━━━━━━━━━━━━━━┛  │
│                           │
└───────────────────────────┘
```

**Key Features**:
- Form fields clearly labeled
- Large picker digits (36pt)
- Grouped related options
- Single primary action at bottom
- Cancel/Save in header

---

## Color Usage Examples

### Status Colors in Context

```
SCHEDULED (Blue)
┌────────────────┐
│ ⏰  6:30      │
│     Wake Up   │
│  [🔵]         │
└────────────────┘

RUNNING (Green)
┌────────────────┐
│ ⏰  7:15      │
│     Gym Time  │
│  [🟢]         │  ← Countdown active
└────────────────┘

PAUSED (Amber)
┌────────────────┐
│ ⏰  8:00      │
│     Breakfast │
│  [🟡]         │  ← User paused
└────────────────┘

ALERTING (Red)
┌────────────────┐
│ 🔔  6:30      │  ← Icon changes
│     Wake Up   │
│  [🔴]         │  ← Pulsing
└────────────────┘
```

---

## Typography Scale Visual

```
HERO TIME (72pt Heavy Mono)
6:30

LARGE TIME (56pt Bold Mono)
7:45

MEDIUM TIME (36pt Semibold)
10:00

HEADER XL (34pt Black)
ALARMS

HEADER LARGE (28pt Heavy)
Settings

HEADER MEDIUM (22pt Bold)
Notifications

HEADER SMALL (17pt Semibold)
Sound Options

BODY LARGE (17pt Regular)
This is the primary body text size

BODY MEDIUM (15pt Regular)
This is for secondary information

BODY SMALL (13pt Regular)
This is for tertiary details

LABEL BOLD (11pt Heavy)
STATUS BADGE

BUTTON PRIMARY (20pt Bold)
CONFIRM ACTION
```

---

## Button States Visual

### Primary Button

```
NORMAL STATE
┏━━━━━━━━━━━━━━━━━┓
┃  SET ALARM      ┃  64pt height
┗━━━━━━━━━━━━━━━━━┛  #FF2B55 background
                      White 20pt Bold text
                      12pt corner radius
                      8pt shadow

PRESSED STATE
┏━━━━━━━━━━━━━━━┓
┃  SET ALARM    ┃    Scaled to 95%
┗━━━━━━━━━━━━━━━┛    Heavy haptic
                      No shadow (flat)

DISABLED STATE
┏━━━━━━━━━━━━━━━━━┓
┃  SET ALARM      ┃  Gray background
┗━━━━━━━━━━━━━━━━━┛  50% opacity
                      No interaction
```

### Secondary Button

```
NORMAL STATE
┌─────────────────┐
│  Edit Details   │  48pt height
└─────────────────┘  Surface background
                     2pt border
                     Tertiary text color

PRESSED STATE
┌─────────────────┐
│  Edit Details   │  Medium haptic
└─────────────────┘  Tinted background
```

---

## Icon + Text Patterns

```
ALARM STATES
🔵 SCHEDULED  - Blue badge, alarm icon
🟢 RUNNING    - Green badge, alarm.fill
🟡 PAUSED     - Amber badge, pause.circle.fill
🔴 ALERTING   - Red badge, bell.badge.fill

ACTIONS
➕ ADD        - plus.circle.fill
🗑️ DELETE     - trash.fill (destructive)
✏️ EDIT       - pencil
⚙️ SETTINGS   - gearshape.fill

TIME/SCHEDULE
📅 CALENDAR   - calendar
🕐 CLOCK      - clock.fill
⏱️ TIMER      - timer
🔁 REPEAT     - repeat
```

---

## Dark Mode Comparison

```
LIGHT MODE                  DARK MODE
┌──────────────┐           ┌──────────────┐
│ ⏰  6:30    │           │ ⏰  6:30    │
│ #000 text   │           │ #FFF text   │
│ #FFF bg     │           │ #000 bg     │
│ [🔵]        │           │ [🔵]        │  ← Same accent
└──────────────┘           └──────────────┘

Primary Button remains #FF2B55 (red) in both modes
Status badges keep semantic colors (no inversion)
Icons remain the same (SF Symbols adapt)
```

---

## Spacing Grid Example

```
Screen Margins: 16pt
┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃←16→                 ←16→┃
┃    ┌─────────────┐      ┃
┃    │   Content   │      ┃  ↕ 16pt padding
┃    └─────────────┘      ┃
┃    ↕ 24pt gap           ┃
┃    ┌─────────────┐      ┃
┃    │   Content   │      ┃
┃    └─────────────┘      ┃
┃                         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━┛

Cell Internal Spacing:
┌──────────────────────┐
│ ↕16                  │
│ ⏰ ←16→ 6:30        │
│      Wake Up         │
│ ↕16                  │
└──────────────────────┘
```

---

## Responsive Considerations

### iPhone SE (Small Screen)
- Maintain 44pt minimum tap targets
- Reduce spacing to 12pt where needed
- Time can scale down to 48pt in lists
- Never compromise button size

### iPhone Pro Max (Large Screen)
- Use full 56pt time in lists
- Increase whitespace (32pt sections)
- Hero time can go to 84pt
- Wider margins (24pt sides)

### iPad
- Multi-column layouts
- Larger headers (40pt+)
- More whitespace between elements
- Side-by-side detail views

---

## Animation Timing Reference

```
INSTANT (0.1s)
- Button press feedback
- Toggle switches
- Checkmarks

QUICK (0.2s)
- Sheet presentation
- Color transitions
- Icon changes

STANDARD (0.3s)
- View transitions
- Card animations
- Slide effects

PULSE (1.0s repeat)
- Active alarm indicator
- Alert badges
- "Get attention" effects
```

---

## Accessibility Overlay Examples

### Voice Over Labels

```
Alarm Cell:
"Wake Up Call alarm, 6:30 AM, Every day, Scheduled. Button."

Primary Button:
"Set Alarm. Button."

Status Badge:
"Status: Scheduled"

Time Picker:
"Hour, 6. Stepper. Increment, Decrement."
```

### Contrast Ratios

```
✓ Black on White: 21:1 (AAA)
✓ White on Red:   4.6:1 (AA Large)
✓ Blue on White:  8.6:1 (AAA)
✓ Body text:      10:1+ (AAA)
```

---

**Visual Examples Version**: 1.0
**Companion to**: DESIGN_SYSTEM.md
