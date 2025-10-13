//
//  NativeMenuListItem.swift
//  fig
//
//  Apple-native menu list item component
//

import SwiftUI

struct NativeMenuListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray5),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: 8) {
        NativeMenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: .blue
        ) {}

        NativeMenuListItem(
            icon: "questionmark.circle",
            title: "FAQ",
            subtitle: "Frequently asked questions",
            iconColor: .purple
        ) {}

        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: .green
        ) {}

        NativeMenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled alarms",
            iconColor: .red
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    VStack(spacing: 8) {
        NativeMenuListItem(
            icon: "info.circle",
            title: "About",
            subtitle: "App version and information",
            iconColor: .blue
        ) {}

        NativeMenuListItem(
            icon: "questionmark.circle",
            title: "FAQ",
            subtitle: "Frequently asked questions",
            iconColor: .purple
        ) {}

        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: .green
        ) {}

        NativeMenuListItem(
            icon: "trash",
            title: "Delete All Data",
            subtitle: "Clear all scheduled alarms",
            iconColor: .red
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
