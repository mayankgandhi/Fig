# Ticker Design System
## Mission-Critical Alarm Interface

> **Design Philosophy**: Ticker is not a decorative clock app. It's a mission-critical tool that demands attention and gets you moving. Every design decision prioritizes urgency, clarity, and reliability over aesthetics.

---

## Design Principles

### 1. **Urgency First**
- Bold, high-contrast visuals that command attention
- Time is always the hero element on screen
- Critical actions are impossible to miss
- No decorative elements that dilute focus

### 2. **Immediate Clarity**
- Information hierarchy is ruthlessly clear
- Status is communicated through multiple channels (color, text, icon)
- No ambiguity about what will happen and when

### 3. **Tactile Reliability**
- Every interaction provides immediate feedback
- Large tap targets prevent errors under pressure
- Haptic responses reinforce critical actions
- Animations only when they communicate state or urgency

### 4. **High-Contrast Accessibility**
- Works perfectly in bright sunlight and complete darkness
- Never relies on color alone to communicate state
- All text meets WCAG AAA standards
- Large, legible typography at all times

---

## Color System

### Base Palette (High Contrast)

```swift
Absolute Black: #000000  // Pure black backgrounds (dark mode)
Absolute White: #FFFFFF  // Pure white backgrounds (light mode)
Surface Dark:   #141414  // Elevated surfaces (dark mode)
Surface Light:  #FAFAFA  // Elevated surfaces (light mode)
```

**Usage**: Maximum contrast between background and content. No gradients, no soft colors.

### Critical Accent (Electric Red)

```swift
Critical Red:   #FF2B55  // Primary actions, urgent states
Alert Active:   #FF4500  // Pulsing alarm indicator
Danger Red:     #EB0000  // Destructive actions
```

**Why Red**:
- Universal danger/urgency signal
- Highest attention-grabbing color
- Creates immediate emotional response
- Works in all lighting conditions

### Semantic State Colors

```swift
Scheduled:  #007AFF  // Cool blue = reliable, future state
Running:    #34D64A  // Electric green = active, in progress
Paused:     #FF9900  // Amber = warning, needs attention
Disabled:   #8E8E93  // Neutral gray = inactive
```

**Multi-Channel Communication**: Every state uses:
1. Color background
2. Icon indicator
3. Text label
4. (Optional) Haptic feedback

---

## Typography System

### Hierarchy

```
TIME DISPLAY (Massive)
├─ Hero Time:    72pt Heavy Rounded Mono
├─ Large Time:   56pt Bold Rounded Mono
└─ Medium Time:  36pt Semibold Rounded Mono

HEADERS (Strong)
├─ XL Header:    34pt Black SF Pro
├─ Large Header: 28pt Heavy SF Pro
├─ Med Header:   22pt Bold SF Pro
└─ Small Header: 17pt Semibold SF Pro

BODY TEXT (Legible)
├─ Large Body:   17pt Regular SF Pro
├─ Medium Body:  15pt Regular SF Pro
└─ Small Body:   13pt Regular SF Pro

LABELS (Bold, Uppercase)
├─ Bold Label:   11pt Heavy SF Pro
└─ Small Label:  10pt Semibold SF Pro

BUTTONS
├─ Primary:      20pt Bold SF Pro
└─ Secondary:    17pt Semibold SF Pro
```

### Font Characteristics

**Time Display**:
- Always rounded design for readability
- Always monospaced digits for stability
- Heavy/bold weights only
- Largest elements on screen

**Headers**:
- Geometric, strong letterforms
- Black/Heavy weights for impact
- Clear visual hierarchy through size

**Body Text**:
- Regular weight for easy scanning
- Generous line height (1.4-1.6)
- Never smaller than 13pt

**Labels/Badges**:
- ALL CAPS for urgency
- Heavy weight for emphasis
- High contrast backgrounds

---

## Spacing System

### Scale (8pt base grid)

```
XXS:  4pt   - Micro spacing
XS:   8pt   - Tiny spacing
SM:   12pt  - Small spacing
MD:   16pt  - Base unit
LG:   24pt  - Medium-large
XL:   32pt  - Large spacing
XXL:  48pt  - Extra large
XXXL: 64pt  - Section breaks
```

### Component Sizing

```
Tap Targets:
- Minimum:   44×44pt (accessibility)
- Preferred: 56×56pt (critical actions)

Buttons:
- Large:     64pt height
- Standard:  48pt height

Icons:
- Large:     32×32pt
- Standard:  24×24pt
- Small:     16×16pt
```

### Padding Rules

- **Screens**: 16pt horizontal margins
- **Cards**: 16-24pt internal padding
- **Lists**: 16pt vertical padding per item
- **Buttons**: 16pt horizontal, 12pt vertical minimum

---

## Layout Principles

### Information Hierarchy (Top to Bottom)

```
┌─────────────────────────────┐
│ 1. TIME (Massive)           │  ← Hero element
│                             │
│ 2. Label/Name (Large)       │  ← What this alarm is
│                             │
│ 3. Schedule Info (Medium)   │  ← When it happens
│                             │
│ 4. Status Badge             │  ← Current state
│                             │
│ 5. Actions                  │  ← What you can do
└─────────────────────────────┘
```

### Screen Templates

**Alarm List Screen**:
```
┌─────────────────────────┐
│ ALARMS             [+]  │  Header (fixed)
├─────────────────────────┤
│                         │
│  ⏰ 6:30 AM            │  Alarm cell
│  Wake Up Call          │  (repeating)
│  Every day        🔵   │
│                         │
├─────────────────────────┤
│  ⏰ 7:15 AM            │
│  Gym Time              │
│  Mon-Fri          🟢   │
└─────────────────────────┘
```

**Alarm Detail**:
```
┌─────────────────────────┐
│      [X]                │
│                         │
│      6:30 AM            │  ← Massive time
│                         │
│    Wake Up Call         │  ← Large label
│                         │
│ 📅 Every day            │  ← Schedule
│                         │
│ [🔴 SCHEDULED]          │  ← Status badge
│                         │
│                         │
│ ┌─────────────────────┐ │
│ │   DISABLE ALARM     │ │  ← Primary action
│ └─────────────────────┘ │
│                         │
│      Edit Details       │  ← Secondary
└─────────────────────────┘
```

---

## Component Specifications

### Primary Button

```swift
Style:
- Background: Critical Red (#FF2B55)
- Text: White, 20pt Bold
- Height: 64pt
- Corner Radius: 12pt
- Shadow: 8pt blur, 4pt offset
- Active State: Scale 0.95 + haptic

Usage: Critical actions only
- "Set Alarm"
- "Dismiss" (when alerting)
- "Delete Alarm" (destructive variant)
```

### Status Badge

```swift
Style:
- Text: UPPERCASE, 11pt Heavy
- Padding: 12pt horizontal, 4pt vertical
- Corner Radius: 4pt tight
- Background: State color (opaque)
- Text Color: Always white

States:
🔵 SCHEDULED  - Blue background
🟢 RUNNING    - Green background
🟡 PAUSED     - Amber background
🔴 ALERTING   - Red background
⚪ DISABLED   - Gray background
```

### Alarm Cell (List Item)

```swift
Layout:
┌─────────────────────────────────┐
│ [Icon]  Name           6:30 AM  │
│         Schedule         [🔵]   │
└─────────────────────────────────┘

Components:
1. Icon (48×48pt circle, colored)
2. Name (17pt Semibold)
3. Time (56pt Bold Mono) ← Right aligned
4. Schedule (13pt Regular)
5. Status badge ← Bottom right

Spacing:
- Height: 88pt minimum
- Internal padding: 16pt
- Icon to text: 16pt gap
```

### Empty State

```swift
Layout:
┌─────────────────────────┐
│                         │
│          ⏰             │  128pt icon
│                         │
│    No Active Alarms     │  28pt Heavy
│                         │
│   Tap + to create one   │  15pt Regular
│                         │
│  ┌───────────────────┐  │
│  │   ADD ALARM       │  │  Primary button
│  └───────────────────┘  │
│                         │
└─────────────────────────┘

Characteristics:
- Centered vertically
- Icon uses tertiary color
- Clear call-to-action
- No decorative elements
```

---

## Interaction Patterns

### Haptic Feedback Map

| Action | Haptic Type | Timing |
|--------|-------------|--------|
| Set alarm | Heavy impact | On confirm |
| Toggle enable/disable | Medium impact | On toggle |
| Delete alarm | Notification error | On confirm |
| Alarm triggered | Continuous vibration | While alerting |
| Time picker scroll | Selection changed | Per item |
| Button tap | Light impact | On touch down |

### Animation Guidelines

**When to Animate**:
✅ State transitions (scheduled → running)
✅ Alarm pulsing when active
✅ Button press feedback
✅ Sheet/modal presentation

**When NOT to Animate**:
❌ List scrolling
❌ Text changes
❌ Icon swaps
❌ Color changes (instant only)

**Duration Rules**:
- Instant feedback: 0.1s
- Standard transitions: 0.2-0.3s
- Urgent pulse: 1.0s repeat

---

## Accessibility Requirements

### Contrast Ratios (WCAG AAA)

| Element | Minimum Ratio | Target |
|---------|--------------|--------|
| Large text (18pt+) | 4.5:1 | 7:1 |
| Body text | 7:1 | 10:1 |
| Status badges | 4.5:1 | 7:1 |
| Icons | 3:1 | 4.5:1 |

### Touch Targets

| Priority | Minimum Size | Preferred |
|----------|--------------|-----------|
| Critical actions | 44×44pt | 56×56pt |
| Standard buttons | 44×44pt | 48×48pt |
| List items | 44pt height | 64pt+ |

### Multi-Channel Status

Every state must communicate through:
1. **Color** - Visual indicator
2. **Text** - Screen reader compatible
3. **Icon** - Universal symbol
4. **Haptic** (optional) - Tactile feedback

**Example**: Alarm scheduled
- 🔵 Blue background
- "SCHEDULED" text label
- 📅 Calendar icon
- (No haptic needed)

---

## Icon Usage Guidelines

### Style
- SF Symbols or equivalent
- Filled variants for active states
- Outline variants for inactive states
- 24×24pt standard size
- 32×32pt for primary actions

### States

| Icon | State | Usage |
|------|-------|-------|
| alarm | Scheduled | Default alarm state |
| alarm.fill | Active | Alarm currently running |
| bell.badge.fill | Alerting | Alarm is ringing |
| pause.circle.fill | Paused | Countdown paused |
| trash.fill | Delete | Destructive action |
| plus.circle.fill | Add | Create new alarm |

---

## Dark Mode Considerations

### Automatic Adaptation

```swift
Background:
Light: #FFFFFF → Dark: #000000

Surface:
Light: #FAFAFA → Dark: #141414

Text Primary:
Light: #000000 → Dark: #FFFFFF

Text Secondary:
Light: #000000 70% → Dark: #FFFFFF 70%

Accent Colors:
No change - always high contrast
```

### Shadows
- Light mode: Black 8-15% opacity
- Dark mode: Black 30% opacity OR white 5% glow

---

## Design File Organization

```
fig/
├── DesignSystem/
│   ├── TickerDesignSystem.swift  ← Core system
│   ├── Colors.swift              ← Color extensions
│   ├── Typography.swift          ← Font extensions
│   └── Components.swift          ← Reusable views
├── Components/
│   ├── AlarmCell.swift
│   ├── StatusBadge.swift
│   ├── PrimaryButton.swift
│   └── TimeDisplay.swift
└── Screens/
    ├── AlarmListView.swift
    ├── AlarmDetailView.swift
    └── AlarmEditorView.swift
```

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Implement TickerDesignSystem.swift
- [ ] Create color extension utilities
- [ ] Create typography view modifiers
- [ ] Set up haptic feedback system

### Phase 2: Components
- [ ] Redesign PrimaryButton with new system
- [ ] Redesign StatusBadge component
- [ ] Create new AlarmCell with urgency focus
- [ ] Build TimeDisplay hero component

### Phase 3: Screens
- [ ] Rebuild AlarmListView
- [ ] Rebuild AlarmDetailView
- [ ] Rebuild AlarmEditorView
- [ ] Update empty states

### Phase 4: Polish
- [ ] Implement all haptic feedback
- [ ] Add state transition animations
- [ ] Test dark mode thoroughly
- [ ] Accessibility audit (contrast, labels, targets)

---

## Design References

**Inspiration** (for urgency/clarity):
- Military HUD interfaces
- Emergency response apps
- Aviation instrument panels
- Industrial control systems

**Anti-Patterns** (avoid):
- Playful illustrations
- Soft gradients
- Small tap targets
- Color-only state indicators
- Excessive animations
- Decorative fonts

---

## Success Metrics

A successful implementation should:
1. ✅ Time visible from 3+ feet away
2. ✅ All actions completable in 2 taps max
3. ✅ Status clear in 1 second glance
4. ✅ Works in bright sunlight
5. ✅ No accidental dismissals
6. ✅ Screen reader friendly
7. ✅ Zero decorative elements

---

**Version**: 1.0
**Last Updated**: October 2025
**Maintained By**: Ticker Design Team
