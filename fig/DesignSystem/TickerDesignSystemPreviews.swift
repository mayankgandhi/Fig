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
                        .cabinetTitle2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.primary, name: "Primary")
                        colorSwatch(color: TickerColors.primaryDark, name: "Primary Dark")
                        colorSwatch(color: TickerColors.accent, name: "Accent")
                    }
                }

                // Semantic Actions
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("SEMANTIC ACTIONS")
                        .cabinetTitle2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.success, name: "Success")
                        colorSwatch(color: TickerColors.warning, name: "Warning")
                        colorSwatch(color: TickerColors.danger, name: "Danger")
                    }
                }

                // Alarm States
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("ALARM STATES")
                        .cabinetTitle2()

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.scheduled, name: "Scheduled")
                        colorSwatch(color: TickerColors.running, name: "Running")
                    }
                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.paused, name: "Paused")
                        colorSwatch(color: TickerColors.alerting, name: "Alerting")
                        colorSwatch(color: TickerColors.disabled, name: "Disabled")
                    }
                }

                // Text Colors
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("TEXT HIERARCHY")
                        .cabinetTitle2()

                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        Text("Primary Text")
                            .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                        Text("Secondary Text")
                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                        Text("Tertiary Text")
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                    }
                    .cabinetBody()
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColors.background(for: colorScheme))
    }

    private func colorSwatch(color: Color, name: String) -> some View {
        VStack(spacing: TickerSpacing.xxs) {
            RoundedRectangle(cornerRadius: TickerRadius.small)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.small)
                        .strokeBorder(TickerColors.textTertiary(for: colorScheme), lineWidth: 1)
                )

            Text(name)
                .cabinetCaption()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
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
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("6:30")
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Hero - 72pt Heavy Mono")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("7:45")
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 56pt Bold Mono")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("10:00")
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    
                    Text("Medium - 36pt Semibold")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }

                Divider()

                // Headers
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("HEADERS")
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("ALARMS")
                        .cabinetLargeTitle()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("XL - 34pt Black")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("Settings")
                        .cabinetTitle()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 28pt Heavy")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("Notifications")
                        .cabinetTitle2()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Medium - 22pt Bold")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }

                Divider()

                // Body Text
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BODY TEXT")
                        .cabinetCaption2()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("This is the primary body text size for main content.")
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 17pt Regular")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("This is for secondary information and details.")
                        .cabinetSubheadline()
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                    Text("Medium - 15pt Regular")
                        .cabinetFootnote()
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColors.background(for: colorScheme))
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
                        .cabinetTitle2()

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
                        .cabinetTitle2()

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
                        .cabinetTitle2()

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
                        .cabinetTitle2()

                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        Text("• Primary: 64pt height")
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("• Secondary: 48pt height")
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("• Tertiary: Flexible padding")
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("• Minimum tap target: 44×44pt")
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("• Press feedback: Scale + opacity")
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                    }
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColors.background(for: colorScheme))
    }
}

// MARK: - Status Badge Preview

struct StatusBadgePreview: View {
    var body: some View {
        VStack(spacing: TickerSpacing.xl) {
            Text("STATUS BADGES")
                .cabinetTitle()

            VStack(alignment: .leading, spacing: TickerSpacing.lg) {
                badgeRow(text: "SCHEDULED", color: TickerColors.scheduled, description: "Blue - Future alarm")
                badgeRow(text: "RUNNING", color: TickerColors.running, description: "Green - Active countdown")
                badgeRow(text: "PAUSED", color: TickerColors.paused, description: "Amber - Needs attention")
                badgeRow(text: "ALERTING", color: TickerColors.alerting, description: "Red - Currently ringing")
                badgeRow(text: "DISABLED", color: TickerColors.disabled, description: "Gray - Inactive")
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
                .cabinetFootnote()
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
                    .cabinetTitle()

                // Scheduled
                mockAlarmCell(
                    icon: "alarm",
                    iconColor: TickerColors.scheduled,
                    label: "Wake Up Call",
                    time: "6:30",
                    schedule: "Every day",
                    status: "SCHEDULED",
                    statusColor: TickerColors.scheduled
                )

                // Running
                mockAlarmCell(
                    icon: "figure.run",
                    iconColor: TickerColors.running,
                    label: "Gym Time",
                    time: "7:15",
                    schedule: "Mon-Fri",
                    status: "RUNNING",
                    statusColor: TickerColors.running
                )

                // Paused
                mockAlarmCell(
                    icon: "fork.knife",
                    iconColor: TickerColors.paused,
                    label: "Breakfast",
                    time: "8:00",
                    schedule: "Paused",
                    status: "PAUSED",
                    statusColor: TickerColors.paused
                )

                // Alerting
                mockAlarmCell(
                    icon: "bell.badge.fill",
                    iconColor: TickerColors.alerting,
                    label: "Meeting Reminder",
                    time: "19:30",
                    schedule: "Once only",
                    status: "ALERTING",
                    statusColor: TickerColors.alerting
                )
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColors.background(for: colorScheme))
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
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                Text(label)
                    .cabinetTitle3()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(schedule)
                }
                .cabinetFootnote()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }

            Spacer()

            // Time + Status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                Text(time)
                    .cabinetTitle()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
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
                .font(.system(size: 128))
                .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

            VStack(spacing: TickerSpacing.xs) {
                Text("No Active Alarms")
                    .cabinetTitle()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                Text("Tap + to create one")
                    .cabinetSubheadline()
                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
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
        .background(TickerColors.background(for: colorScheme))
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
        .background(TickerColors.background(for: colorScheme))
    }

    private func iconSection(title: String, icons: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            Text(title)
                .cabinetTitle2()

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
                .font(.system(size: 32))
                .foregroundStyle(TickerColors.primary)
                .frame(width: 60, height: 60)

            Text(label)
                .cabinetCaption2()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
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
                    .cabinetTitle()

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
                    .cabinetTitle2()

                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    componentSize(height: TickerSpacing.tapTargetMin, label: "Minimum Tap Target - 44pt")
                    componentSize(height: TickerSpacing.tapTargetPreferred, label: "Preferred Tap - 56pt")
                    componentSize(height: TickerSpacing.buttonHeightLarge, label: "Large Button - 64pt")
                    componentSize(height: TickerSpacing.buttonHeightStandard, label: "Standard Button - 48pt")
                }
            }
            .padding(TickerSpacing.md)
        }
        .background(TickerColors.background(for: colorScheme))
    }

    private func spacingBar(size: CGFloat, label: String) -> some View {
        HStack(spacing: TickerSpacing.md) {
            RoundedRectangle(cornerRadius: TickerRadius.tight)
                .fill(TickerColors.primary)
                .frame(width: size, height: 24)

            Text(label)
                .cabinetSubheadline()
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
        }
    }

    private func componentSize(height: CGFloat, label: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            Text(label)
                .cabinetFootnote()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColors.surface(for: colorScheme))
                .frame(height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(TickerColors.primary, lineWidth: 2)
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
