import SwiftUI
import Roadmap
import TickerCore

struct RoadmapScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private let configuration = RoadmapConfiguration(
        sidetrackRoadmapId: "68ffc826a07c4c109a21d199",
        style: RoadmapTemplate.playful.style,
        allowVotes: true,
        allowSearching: false
    )

    var body: some View {
        ZStack {
            // Liquid Glass background
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()

            // Subtle overlay for glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()

            // Main content
            RoadmapView(
                configuration: configuration,
                header: { header },
                footer: { footer }
            )
        }
        .navigationTitle("Roadmap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    TickerHaptics.selection()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .Headline()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            // Hero section with icon
            HStack(spacing: TickerSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    TickerColor.accent,
                                    TickerColor.accent.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: TickerColor.accent.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    Image(systemName: "list.bullet.rectangle.fill")
                        .Title2()
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text("Ticker Roadmap")
                        .Title2()
                        .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                    Text("Shape the future together")
                        .DetailText()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }
            .padding(.top, TickerSpacing.md)

            // Description card
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("Help us build Ticker by voting on features you'd like to see or submitting your own ideas. Your feedback directly influences our development priorities.")
                    .Callout()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .lineSpacing(4)

                // Quick stats
                HStack(spacing: TickerSpacing.md) {
                    featureBadge(icon: "arrow.up.circle.fill", text: "Vote", color: TickerColor.success)
                    featureBadge(icon: "plus.circle.fill", text: "Suggest", color: TickerColor.primary)
                    featureBadge(icon: "chart.bar.fill", text: "Track", color: TickerColor.accent)
                }
                .padding(.top, TickerSpacing.xs)
            }
            .padding(TickerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .fill(TickerColor.surface(for: colorScheme))
                    .shadow(
                        color: TickerShadow.subtle.color,
                        radius: TickerShadow.subtle.radius,
                        x: TickerShadow.subtle.x,
                        y: TickerShadow.subtle.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(
                        TickerColor.textTertiary(for: colorScheme).opacity(0.2),
                        lineWidth: 0.5
                    )
            )
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.bottom, TickerSpacing.lg)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: TickerSpacing.md) {
            // Divider
            Rectangle()
                .fill(TickerColor.textTertiary(for: colorScheme).opacity(0.2))
                .frame(height: 0.5)
                .padding(.horizontal, TickerSpacing.md)

            // Footer content
            VStack(spacing: TickerSpacing.sm) {
                // Thank you message
                HStack(spacing: TickerSpacing.sm) {
                    Image(systemName: "heart.fill")
                        .ButtonText()
                        .foregroundStyle(TickerColor.danger)

                    Text("Thank you for helping shape Ticker")
                        .Callout()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }

                // App branding
                Text("Made with care for time-conscious people")
                    .SmallText()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }
            .padding(.vertical, TickerSpacing.lg)
        }
    }

    // MARK: - Helper Views

    private func featureBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: TickerSpacing.xxs) {
            Image(systemName: icon)
                .SmallText()
                .foregroundStyle(color)

            Text(text)
                .SmallText()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
        }
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xxs)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview("Light Mode") {
    NavigationStack {
        RoadmapScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        RoadmapScreen()
    }
    .preferredColorScheme(.dark)
}


