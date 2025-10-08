# Ticker Design System

## 📋 Overview

This is a complete design system for **Ticker**, a super-powered alarm app designed for people who ignore regular notifications. The system embodies urgency, reliability, and focus through bold, minimal, high-contrast design.

---

## 🗂️ Documentation Files

### Core Design System
1. **`TickerDesignSystem.swift`** - Complete Swift implementation
   - Color system (high-contrast palette)
   - Typography scale (72pt-10pt)
   - Spacing system (4pt-64pt)
   - View modifiers and components
   - Haptic feedback system
   - Icon catalog

2. **`DESIGN_SYSTEM.md`** - Design philosophy and specifications
   - Design principles
   - Color palette with hex codes
   - Typography hierarchy
   - Layout templates
   - Component specifications
   - Accessibility requirements
   - Dark mode guidelines

3. **`VISUAL_EXAMPLES.md`** - ASCII mockups and examples
   - Screen layouts (List, Detail, Editor)
   - Component variations
   - Color usage examples
   - Typography scale visual
   - Dark mode comparisons
   - Animation timing reference

4. **`IMPLEMENTATION_GUIDE.md`** - Code examples and patterns
   - Quick start guide
   - Component implementations
   - Screen templates
   - Common patterns
   - Migration checklist
   - Performance tips

---

## 🎨 Design Philosophy

### Mission-Critical, Not Decorative

Ticker is designed like a **mission-critical tool** — think aviation instruments, emergency response systems, industrial controls. Every design decision prioritizes:

1. **Urgency** - Bold visuals that demand attention
2. **Clarity** - Information hierarchy is ruthlessly clear
3. **Reliability** - Works in all conditions (bright sun, darkness)
4. **Accessibility** - High contrast, large targets, multi-channel feedback

### What Makes This Different

**Traditional Alarm Apps**:
- Soft, playful aesthetics
- Decorative elements
- Small, delicate typography
- Easy to dismiss

**Ticker**:
- Bold, urgent aesthetics
- Zero decorative elements
- Massive, commanding typography
- Impossible to ignore

---

## 🎯 Key Features

### 1. Electric Red Accent
- Single strong accent color (#FF2B55)
- Maximum attention-grabbing
- Used sparingly for critical actions only
- Never for decoration

### 2. Massive Typography
```
72pt - Hero time display
56pt - List view times
36pt - Medium displays
34pt - Screen headers
```

### 3. High-Contrast Everything
- Pure black/white backgrounds
- Text meets WCAG AAA (7:1 minimum)
- Works in bright sunlight
- Perfect in complete darkness

### 4. Large Tap Targets
- Minimum: 44×44pt (accessibility)
- Preferred: 56×56pt (critical actions)
- Primary buttons: 64pt height
- No accidental taps under pressure

### 5. Multi-Channel Status
Every alarm state communicates through:
- **Color** (visual)
- **Text** (screen reader)
- **Icon** (universal)
- **Haptic** (tactile)

### 6. Purposeful Animation
Only animates when it reinforces urgency:
- ✅ Pulsing red circles when alerting
- ✅ Button press feedback (0.1s)
- ✅ State transitions (0.2s)
- ❌ No decorative animations
- ❌ No unnecessary motion

---

## 📐 Core Specifications

### Color Palette

```swift
// Base
Absolute Black:  #000000
Absolute White:  #FFFFFF
Surface Dark:    #141414
Surface Light:   #FAFAFA

// Critical Accent
Critical Red:    #FF2B55  // Primary actions
Alert Active:    #FF4500  // Pulsing alarm
Danger Red:      #EB0000  // Destructive

// Semantic States
Scheduled:       #007AFF  // Blue
Running:         #34D64A  // Green
Paused:          #FF9900  // Amber
Disabled:        #8E8E93  // Gray
```

### Typography Scale

```swift
timeHero:        72pt Heavy Rounded Mono
timeLarge:       56pt Bold Rounded Mono
timeMedium:      36pt Semibold Rounded Mono
headerXL:        34pt Black
headerLarge:     28pt Heavy
bodyLarge:       17pt Regular
labelBold:       11pt Heavy Uppercase
buttonPrimary:   20pt Bold
```

### Spacing

```swift
xxs: 4pt   xs: 8pt   sm: 12pt  md: 16pt
lg: 24pt   xl: 32pt  xxl: 48pt xxxl: 64pt
```

---

## 🚀 Quick Start

### 1. Add to Your Project

```swift
// Copy TickerDesignSystem.swift to your project
import SwiftUI
```

### 2. Use Pre-built Modifiers

```swift
// Primary button (red, 64pt)
Button("SET ALARM") {
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

### 3. Access Design Tokens

```swift
// Colors
.foregroundStyle(TickerColors.criticalRed)
.background(TickerColors.background(for: colorScheme))

// Typography
.font(TickerTypography.timeHero)
.font(TickerTypography.headerLarge)

// Spacing
.padding(TickerSpacing.md)
.frame(height: TickerSpacing.buttonHeightLarge)

// Haptics
TickerHaptics.criticalAction()  // Heavy impact
TickerHaptics.success()          // Success notification
```

---

## 📱 Example Screens

### Alarm List

```
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ALARMS            [+] ┃  ← 34pt Black header
┡━━━━━━━━━━━━━━━━━━━━━━━┩
│ ⏰  6:30              │  ← 56pt Bold time
│     Wake Up Call      │  ← 17pt Semibold
│     Every day    [🔵] │  ← Status badge
├───────────────────────┤
│ 💪  7:15              │
│     Gym Time          │
│     Mon-Fri      [🟢] │  ← Running state
└───────────────────────┘
```

### Alarm Detail

```
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃      [X]              ┃
┃                       ┃
┃      6:30             ┃  ← 72pt Hero time
┃       AM              ┃
┃                       ┃
┃   Wake Up Call        ┃  ← 28pt Heavy
┃                       ┃
┃ 📅 Every day          ┃
┃ [🔵 SCHEDULED]        ┃  ← Badge
┃                       ┃
┃ ┏━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃ DISABLE ALARM   ┃ ┃  ← Primary button
┃ ┗━━━━━━━━━━━━━━━━━┛ ┃
┃   Edit Details        ┃  ← Secondary
└───────────────────────┘
```

### Active Alert

```
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃      🔴 🔴 🔴        ┃  ← Pulsing indicators
┃                       ┃
┃      6:30             ┃
┃       AM              ┃
┃                       ┃
┃   Wake Up Call        ┃
┃ [🔴 ALERTING]         ┃  ← Red, pulsing
┃                       ┃
┃ ┏━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃   DISMISS       ┃ ┃  ← Critical action
┃ ┗━━━━━━━━━━━━━━━━━┛ ┃
┃ ┌─────────────────┐ ┃
┃ │ SNOOZE 5 MIN    │ ┃  ← Secondary
┃ └─────────────────┘ ┃
└───────────────────────┘
```

---

## ✅ Implementation Checklist

### Phase 1: Foundation
- [ ] Add `TickerDesignSystem.swift` to project
- [ ] Test color system in light/dark modes
- [ ] Verify typography scales correctly
- [ ] Set up haptic feedback

### Phase 2: Components
- [ ] Create `TickerPrimaryButton`
- [ ] Create `TickerStatusBadge`
- [ ] Create `TimeDisplay` component
- [ ] Redesign `AlarmCell`

### Phase 3: Screens
- [ ] Implement alarm list with new design
- [ ] Implement alarm detail view
- [ ] Implement alarm editor
- [ ] Update empty states

### Phase 4: Polish
- [ ] Add haptic feedback to all interactions
- [ ] Implement pulsing alert animation
- [ ] Test accessibility (VoiceOver, contrast)
- [ ] Performance optimization

---

## 🎯 Design Goals Met

✅ **Urgency**: Time is always the hero element
✅ **Clarity**: Status visible in < 1 second glance
✅ **Reliability**: Works in all lighting conditions
✅ **Focus**: Zero decorative elements
✅ **Accessibility**: WCAG AAA compliant
✅ **Tactile**: Large targets, haptic feedback
✅ **Mission-Critical**: Impossible to ignore

---

## 📊 Metrics for Success

A successful implementation should achieve:

1. ✅ Time visible from 3+ feet away
2. ✅ All actions completable in ≤2 taps
3. ✅ Status clear in <1 second glance
4. ✅ Readable in bright sunlight
5. ✅ Zero accidental dismissals
6. ✅ VoiceOver compatible
7. ✅ Contrast ratio ≥7:1 (AAA)

---

## 🔧 Tools & Resources

### Design Tools
- Sketch/Figma templates (create from mockups)
- SF Symbols app (icon exploration)
- Xcode Color Picker (hex to Color)
- Accessibility Inspector (contrast testing)

### Code Tools
- SwiftLint (code quality)
- Preview variations (light/dark/accessibility)
- Haptic feedback simulator

### Testing
- Real devices in bright sunlight
- Dark room testing
- VoiceOver navigation
- Large text sizes (accessibility)

---

## 📚 Further Reading

- [Human Interface Guidelines - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [SF Symbols Reference](https://developer.apple.com/sf-symbols/)
- [Haptic Feedback Guidelines](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)

---

## 🤝 Contributing

### Adding New Components

1. Follow existing patterns in `TickerDesignSystem.swift`
2. Use design tokens (colors, spacing, typography)
3. Include haptic feedback where appropriate
4. Test in light/dark modes
5. Verify accessibility

### Proposing Changes

Before modifying the design system:
1. Ensure it serves the mission-critical philosophy
2. Maintain urgency and clarity
3. Keep accessibility top priority
4. Document with examples

---

## 📄 License

This design system is part of the Ticker project.

---

## 🎨 Design System Summary

| Aspect | Specification |
|--------|--------------|
| **Philosophy** | Mission-critical, urgent, reliable |
| **Accent Color** | Electric Red (#FF2B55) |
| **Typography** | 72pt-10pt, SF Pro + Rounded |
| **Contrast** | High (WCAG AAA, 7:1+) |
| **Spacing** | 8pt grid, 4pt-64pt scale |
| **Targets** | 44pt minimum, 56pt preferred |
| **Animations** | Purposeful only, 0.1s-1.0s |
| **Haptics** | Multi-context feedback |
| **Dark Mode** | Full support, high contrast |
| **Files** | 4 docs + 1 Swift implementation |

---

**Design System Version**: 1.0
**Created**: October 2025
**Status**: Ready for Implementation

🚨 **Remember**: This isn't just an alarm app — it's a mission-critical tool that gets people up and moving. Design every element with urgency and purpose.
