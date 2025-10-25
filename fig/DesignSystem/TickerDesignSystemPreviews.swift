//
//  TickerDesignSystemPreviews.swift
//  Ticker
//
//  Comprehensive preview showcases for the design system
//

import SwiftUI

// MARK: - Color System Preview

struct ColorSystemPreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Brand Colors
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BRAND COLORS")
                        .Title2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColor.primary, name: "Primary")
                        colorSwatch(color: TickerColor.primaryDark, name: "Primary Dark")
                        colorSwatch(color: TickerColor.accent, name: "Accent")
                    }
                }

                // Semantic Actions
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("SEMANTIC ACTIONS")
                        .Title2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColor.success, name: "Success")
                        colorSwatch(color: TickerColor.warning, name: "Warning")
                        colorSwatch(color: TickerColor.danger, name: "Danger")
                    }
                }

                // Alarm States
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("ALARM STATES")
                        .Title2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColor.scheduled, name: "Scheduled")
                        colorSwatch(color: TickerColor.running, name: "Running")
                    }
                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColor.paused, name: "Paused")
                        colorSwatch(color: TickerColor.alerting, name: "Alerting")
                        colorSwatch(color: TickerColor.disabled, name: "Disabled")
                    }
                }

                // Text Colors
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("TEXT HIERARCHY")
                        .Title2()

                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        Text("Primary Text")
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                        Text("Secondary Text")
                            .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        Text("Tertiary Text")
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    }
                    .Body()
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }

    private func colorSwatch(color: Color, name: String) -> some View {
        VStack(spacing: TickerSpacing.xxs) {
            RoundedRectangle(cornerRadius: TickerRadius.small)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.small)
                        .strokeBorder(TickerColor.textTertiary(for: colorScheme), lineWidth: 1)
                )

            Text(name)
                .Caption()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}

// MARK: - Typography Scale Preview

struct TypographyScalePreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TickerSpacing.xl) {
                // Time Display
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("TIME DISPLAY")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Text("6:30")
                        .Caption2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("Hero - 72pt Heavy Mono")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                    Text("7:45")
                        .Caption2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("Large - 56pt Bold Mono")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                    Text("10:00")
                        .Caption2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    
                    Text("Medium - 36pt Semibold")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                }

                Divider()

                // Headers
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("HEADERS")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Text("Tickers")
                        .LargeTitle()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("XL - 34pt Black")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                    Text("Settings")
                        .Title()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("Large - 28pt Heavy")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                    Text("Notifications")
                        .Title2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("Medium - 22pt Bold")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                }

                Divider()

                // Body Text
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BODY TEXT")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

                    Text("This is the primary body text size for main content.")
                        .Body()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    Text("Large - 17pt Regular")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                    Text("This is for secondary information and details.")
                        .Subheadline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    Text("Medium - 15pt Regular")
                        .Footnote()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }
}

// MARK: - Button System Preview

struct ButtonSystemPreview: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isButtonDisabled = false

    var body: some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Primary Buttons
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("PRIMARY BUTTONS")
                        .Title2()

                    Button {
                        TickerHaptics.criticalAction()
                    } label: {
                        Text("SET ALARM")
                    }
                    .tickerPrimaryButton()

                    Button {
                        TickerHaptics.error()
                    } label: {
                        Text("DELETE ALARM")
                    }
                    .tickerPrimaryButton(isDestructive: true)

                    Button {
                        // Disabled button
                    } label: {
                        Text("DISABLED STATE")
                    }
                    .tickerPrimaryButton()
                    .disabled(true)
                }

                // Secondary Buttons
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("SECONDARY BUTTONS")
                        .Title2()

                    Button {
                        TickerHaptics.standardAction()
                    } label: {
                        Text("Edit Details")
                    }
                    .tickerSecondaryButton()

                    Button {
                        TickerHaptics.standardAction()
                    } label: {
                        Text("Cancel")
                    }
                    .tickerSecondaryButton()

                    Button {
                        // Disabled button
                    } label: {
                        Text("Disabled State")
                    }
                    .tickerSecondaryButton()
                    .disabled(true)
                }

                // Tertiary Buttons
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("TERTIARY BUTTONS")
                        .Title2()

                    HStack {
                        Button {
                            TickerHaptics.selection()
                        } label: {
                            Text("Skip")
                        }
                        .tickerTertiaryButton()

                        Spacer()

                        Button {
                            TickerHaptics.selection()
                        } label: {
                            Text("Learn More")
                        }
                        .tickerTertiaryButton()
                    }

                    Button {
                        // Disabled button
                    } label: {
                        Text("Disabled Action")
                    }
                    .tickerTertiaryButton()
                    .disabled(true)
                }

                // Button Sizes & States
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BUTTON INFO")
                        .Title2()

                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        Text("• Primary: 64pt height")
                            .Footnote()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                        Text("• Secondary: 48pt height")
                            .Footnote()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                        Text("• Tertiary: Flexible padding")
                            .Footnote()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                        Text("• Minimum tap target: 44×44pt")
                            .Footnote()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                        Text("• Press feedback: Scale + opacity")
                            .Footnote()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    }
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }
}

// MARK: - Status Badge Preview

struct StatusBadgePreview: View {
    var body: some View {
        VStack(spacing: TickerSpacing.xl) {
            Text("STATUS BADGES")
                .Title()

            VStack(alignment: .leading, spacing: TickerSpacing.lg) {
                badgeRow(text: "SCHEDULED", color: TickerColor.scheduled, description: "Blue - Future alarm")
                badgeRow(text: "RUNNING", color: TickerColor.running, description: "Green - Active countdown")
                badgeRow(text: "PAUSED", color: TickerColor.paused, description: "Amber - Needs attention")
                badgeRow(text: "ALERTING", color: TickerColor.alerting, description: "Red - Currently ringing")
                badgeRow(text: "DISABLED", color: TickerColor.disabled, description: "Gray - Inactive")
            }

            Spacer()
        }
        .padding(TickerSpacing.md)
    }

    private func badgeRow(text: String, color: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            Text(text)
                .tickerStatusBadge(color: color)

            Text(description)
                .Footnote()
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Alarm Cell Preview

struct AlarmCellPreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: TickerSpacing.md) {
                Text("ALARM CELLS")
                    .Title()

                // Scheduled
                mockAlarmCell(
                    icon: "alarm",
                    iconColor: TickerColor.scheduled,
                    label: "Wake Up Call",
                    time: "6:30",
                    schedule: "Every day",
                    status: "SCHEDULED",
                    statusColor: TickerColor.scheduled
                )

                // Running
                mockAlarmCell(
                    icon: "figure.run",
                    iconColor: TickerColor.running,
                    label: "Gym Time",
                    time: "7:15",
                    schedule: "Mon-Fri",
                    status: "RUNNING",
                    statusColor: TickerColor.running
                )

                // Paused
                mockAlarmCell(
                    icon: "fork.knife",
                    iconColor: TickerColor.paused,
                    label: "Breakfast",
                    time: "8:00",
                    schedule: "Paused",
                    status: "PAUSED",
                    statusColor: TickerColor.paused
                )

                // Alerting
                mockAlarmCell(
                    icon: "bell.badge.fill",
                    iconColor: TickerColor.alerting,
                    label: "Meeting Reminder",
                    time: "19:30",
                    schedule: "Once only",
                    status: "ALERTING",
                    statusColor: TickerColor.alerting
                )
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }

    private func mockAlarmCell(
        icon: String,
        iconColor: Color,
        label: String,
        time: String,
        schedule: String,
        status: String,
        statusColor: Color
    ) -> some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(.title2, design: .rounded, weight: .regular))
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(label)
                    .Title3()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .Caption2()
                    Text(schedule)
                }
                .Footnote()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }

            Spacer()

            // Time + Status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                Text(time)
                    .Title()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .monospacedDigit()

                Text(status)
                    .tickerStatusBadge(color: statusColor)
            }
        }
        .padding(TickerSpacing.md)
        .frame(minHeight: TickerSpacing.tapTargetPreferred)
        .tickerCard()
        .contentShape(Rectangle())
    }
}

// MARK: - Empty State Preview

struct EmptyStatePreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: TickerSpacing.xl) {
            Spacer()

            Image(systemName: TickerIcons.alarmScheduled)
                .font(.system(.largeTitle, design: .rounded, weight: .regular))
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

            VStack(spacing: TickerSpacing.xs) {
                Text("No Active Tickers")
                    .Title()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                Text("Tap + to create one")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }

            Button {
                TickerHaptics.criticalAction()
            } label: {
                Text("ADD ALARM")
            }
            .tickerPrimaryButton()
            .padding(.horizontal, TickerSpacing.xxl)

            Spacer()
        }
        .background(TickerColor.background(for: colorScheme))
    }
}

// MARK: - Icon System Preview

struct IconSystemPreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TickerSpacing.xl) {
                // Alarm States
                iconSection(title: "ALARM STATES", icons: [
                    (TickerIcons.alarmScheduled, "Scheduled"),
                    (TickerIcons.alarmRunning, "Running"),
                    (TickerIcons.alarmPaused, "Paused"),
                    (TickerIcons.alarmAlerting, "Alerting")
                ])

                // Actions
                iconSection(title: "ACTIONS", icons: [
                    (TickerIcons.add, "Add"),
                    (TickerIcons.delete, "Delete"),
                    (TickerIcons.edit, "Edit"),
                    (TickerIcons.settings, "Settings"),
                    (TickerIcons.close, "Close"),
                    (TickerIcons.checkmark, "Check")
                ])

                // Time/Schedule
                iconSection(title: "TIME & SCHEDULE", icons: [
                    (TickerIcons.calendar, "Calendar"),
                    (TickerIcons.clock, "Clock"),
                    (TickerIcons.timer, "Timer"),
                    (TickerIcons.repeat, "Repeat")
                ])

                // Status
                iconSection(title: "STATUS", icons: [
                    (TickerIcons.warning, "Warning"),
                    (TickerIcons.error, "Error"),
                    (TickerIcons.success, "Success"),
                    (TickerIcons.info, "Info")
                ])
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }

    private func iconSection(title: String, icons: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text(title)
                .Title2()

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80))
            ], spacing: TickerSpacing.md) {
                ForEach(icons, id: \.0) { icon in
                    iconItem(name: icon.0, label: icon.1)
                }
            }
        }
    }

    private func iconItem(name: String, label: String) -> some View {
        VStack(spacing: TickerSpacing.xs) {
            Image(systemName: name)
                .font(.system(.title2, design: .rounded, weight: .regular))
                .foregroundStyle(TickerColor.primary)
                .frame(width: 60, height: 60)

            Text(label)
                .Caption2()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Spacing System Preview

struct SpacingSystemPreview: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TickerSpacing.xl) {
                Text("SPACING SYSTEM")
                    .Title()

                VStack(alignment: .leading, spacing: TickerSpacing.lg) {
                    spacingBar(size: TickerSpacing.xxs, label: "XXS - 4pt")
                    spacingBar(size: TickerSpacing.xs, label: "XS - 8pt")
                    spacingBar(size: TickerSpacing.sm, label: "SM - 12pt")
                    spacingBar(size: TickerSpacing.md, label: "MD - 16pt")
                    spacingBar(size: TickerSpacing.lg, label: "LG - 24pt")
                    spacingBar(size: TickerSpacing.xl, label: "XL - 32pt")
                    spacingBar(size: TickerSpacing.xxl, label: "XXL - 48pt")
                    spacingBar(size: TickerSpacing.xxxl, label: "XXXL - 64pt")
                }

                Divider()

                Text("COMPONENT SIZING")
                    .Title2()

                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    componentSize(height: TickerSpacing.tapTargetMin, label: "Minimum Tap Target - 44pt")
                    componentSize(height: TickerSpacing.tapTargetPreferred, label: "Preferred Tap - 56pt")
                    componentSize(height: TickerSpacing.buttonHeightLarge, label: "Large Button - 64pt")
                    componentSize(height: TickerSpacing.buttonHeightStandard, label: "Standard Button - 48pt")
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColor.background(for: colorScheme))
    }

    private func spacingBar(size: CGFloat, label: String) -> some View {
        HStack(spacing: TickerSpacing.md) {
            RoundedRectangle(cornerRadius: TickerRadius.tight)
                .fill(TickerColor.primary)
                .frame(width: size, height: 24)

            Text(label)
                .Subheadline()
                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
        }
    }

    private func componentSize(height: CGFloat, label: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            Text(label)
                .Footnote()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColor.surface(for: colorScheme))
                .frame(height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(TickerColor.primary, lineWidth: 2)
                )
        }
    }
}

// MARK: - Preview Providers

#Preview("Colors") {
    ColorSystemPreview()
}

#Preview("Colors - Dark") {
    ColorSystemPreview()
        .preferredColorScheme(.dark)
}

#Preview("Typography") {
    TypographyScalePreview()
}

#Preview("Buttons") {
    ButtonSystemPreview()
}

#Preview("Status Badges") {
    StatusBadgePreview()
}

#Preview("Alarm Cells") {
    AlarmCellPreview()
}

#Preview("Empty State") {
    EmptyStatePreview()
}

#Preview("Icons") {
    IconSystemPreview()
}

#Preview("Spacing") {
    SpacingSystemPreview()
}

// MARK: - Complete Showcase

struct TickerDesignShowcase: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ColorSystemPreview()
                .tabItem {
                    Label("Colors", systemImage: "paintpalette")
                }
                .tag(0)

            TypographyScalePreview()
                .tabItem {
                    Label("Typography", systemImage: "textformat")
                }
                .tag(1)

            ButtonSystemPreview()
                .tabItem {
                    Label("Buttons", systemImage: "rectangle.fill")
                }
                .tag(2)

            StatusBadgePreview()
                .tabItem {
                    Label("Badges", systemImage: "tag")
                }
                .tag(3)

            AlarmCellPreview()
                .tabItem {
                    Label("Cells", systemImage: "list.bullet")
                }
                .tag(4)

            IconSystemPreview()
                .tabItem {
                    Label("Icons", systemImage: "star")
                }
                .tag(5)

            SpacingSystemPreview()
                .tabItem {
                    Label("Spacing", systemImage: "square.grid.3x3")
                }
                .tag(6)
        }
    }
}

#Preview("Complete Showcase") {
    TickerDesignShowcase()
}

#Preview("Complete Showcase - Dark") {
    TickerDesignShowcase()
        .preferredColorScheme(.dark)
}
