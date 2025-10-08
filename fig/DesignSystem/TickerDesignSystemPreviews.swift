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
                // Critical Colors
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("CRITICAL ACCENT")
                        .font(TickerTypography.headerMedium)

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.criticalRed, name: "Critical Red")
                        colorSwatch(color: TickerColors.alertActive, name: "Alert Active")
                        colorSwatch(color: TickerColors.danger, name: "Danger")
                    }
                }

                // Semantic States
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("SEMANTIC STATES")
                        .font(TickerTypography.headerMedium)

                    HStack(spacing: TickerSpacing.sm) {
                        colorSwatch(color: TickerColors.scheduled, name: "Scheduled")
                        colorSwatch(color: TickerColors.running, name: "Running")
                        colorSwatch(color: TickerColors.paused, name: "Paused")
                        colorSwatch(color: TickerColors.disabled, name: "Disabled")
                    }
                }

                // Text Colors
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("TEXT HIERARCHY")
                        .font(TickerTypography.headerMedium)

                    VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                        Text("Primary Text")
                            .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                        Text("Secondary Text")
                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                        Text("Tertiary Text")
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                    }
                    .font(TickerTypography.bodyLarge)
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
                .font(TickerTypography.labelSmall)
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
                        .font(TickerTypography.labelBold)
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("6:30")
                        .font(TickerTypography.timeHero)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Hero - 72pt Heavy Mono")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("7:45")
                        .font(TickerTypography.timeLarge)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 56pt Bold Mono")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("10:00")
                        .font(TickerTypography.timeMedium)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Medium - 36pt Semibold")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }

                Divider()

                // Headers
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("HEADERS")
                        .font(TickerTypography.labelBold)
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("ALARMS")
                        .font(TickerTypography.headerXL)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("XL - 34pt Black")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("Settings")
                        .font(TickerTypography.headerLarge)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 28pt Heavy")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("Notifications")
                        .font(TickerTypography.headerMedium)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Medium - 22pt Bold")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                }

                Divider()

                // Body Text
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BODY TEXT")
                        .font(TickerTypography.labelBold)
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

                    Text("This is the primary body text size for main content.")
                        .font(TickerTypography.bodyLarge)
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    Text("Large - 17pt Regular")
                        .font(TickerTypography.bodySmall)
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                    Text("This is for secondary information and details.")
                        .font(TickerTypography.bodyMedium)
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                    Text("Medium - 15pt Regular")
                        .font(TickerTypography.bodySmall)
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

    var body: some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Primary Buttons
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("PRIMARY BUTTONS")
                        .font(TickerTypography.headerMedium)

                    Button {
                        TickerHaptics.criticalAction()
                    } label: {
                        Text("SET ALARM")
                            .frame(maxWidth: .infinity)
                    }
                    .tickerPrimaryButton()

                    Button {
                        TickerHaptics.error()
                    } label: {
                        Text("DELETE ALARM")
                            .frame(maxWidth: .infinity)
                    }
                    .tickerPrimaryButton(isDestructive: true)
                }

                // Secondary Buttons
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("SECONDARY BUTTONS")
                        .font(TickerTypography.headerMedium)

                    Button {
                        TickerHaptics.standardAction()
                    } label: {
                        Text("Edit Details")
                            .frame(maxWidth: .infinity)
                    }
                    .tickerSecondaryButton()

                    Button {
                        TickerHaptics.standardAction()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .tickerSecondaryButton()
                }

                // Button Sizes
                VStack(alignment: .leading, spacing: TickerSpacing.md) {
                    Text("BUTTON SIZES")
                        .font(TickerTypography.headerMedium)

                    VStack(spacing: TickerSpacing.xs) {
                        Text("Primary: 64pt height")
                            .font(TickerTypography.bodySmall)
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("Secondary: 48pt height")
                            .font(TickerTypography.bodySmall)
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))

                        Text("Minimum tap target: 44×44pt")
                            .font(TickerTypography.bodySmall)
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
                .font(TickerTypography.headerLarge)

            VStack(alignment: .leading, spacing: TickerSpacing.lg) {
                badgeRow(text: "SCHEDULED", color: TickerColors.scheduled, description: "Blue - Future alarm")
                badgeRow(text: "RUNNING", color: TickerColors.running, description: "Green - Active countdown")
                badgeRow(text: "PAUSED", color: TickerColors.paused, description: "Amber - Needs attention")
                badgeRow(text: "ALERTING", color: TickerColors.alertActive, description: "Red - Currently ringing")
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
                .font(TickerTypography.bodySmall)
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
                    .font(TickerTypography.headerLarge)

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
                    iconColor: TickerColors.alertActive,
                    label: "Meeting Reminder",
                    time: "19:30",
                    schedule: "Once only",
                    status: "ALERTING",
                    statusColor: TickerColors.alertActive
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
                    .font(TickerTypography.headerSmall)
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(schedule)
                }
                .font(TickerTypography.bodySmall)
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }

            Spacer()

            // Time + Status
            VStack(alignment: .trailing, spacing: TickerSpacing.xs) {
                Text(time)
                    .font(TickerTypography.timeLarge)
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
                    .font(TickerTypography.headerLarge)
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                Text("Tap + to create one")
                    .font(TickerTypography.bodyMedium)
                    .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            }

            Button {
                TickerHaptics.criticalAction()
            } label: {
                Text("ADD ALARM")
                    .frame(maxWidth: .infinity)
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
                .font(TickerTypography.headerMedium)

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
                .foregroundStyle(TickerColors.criticalRed)
                .frame(width: 60, height: 60)

            Text(label)
                .font(TickerTypography.labelSmall)
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
                    .font(TickerTypography.headerLarge)

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
                    .font(TickerTypography.headerMedium)

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
                .fill(TickerColors.criticalRed)
                .frame(width: size, height: 24)

            Text(label)
                .font(TickerTypography.bodyMedium)
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
        }
    }

    private func componentSize(height: CGFloat, label: String) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            Text(label)
                .font(TickerTypography.bodySmall)
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))

            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(TickerColors.surface(for: colorScheme))
                .frame(height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(TickerColors.criticalRed, lineWidth: 2)
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
