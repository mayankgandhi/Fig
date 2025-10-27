//
//  AITickerGeneratorDebugView.swift
//  fig
//
//  Debug view for testing AITickerGenerator with live event logging
//  Only available in Debug/Development builds
//

import SwiftUI

#if DEBUG
struct AITickerGeneratorDebugView: View {
    @ObservedObject var aiGenerator: AITickerGenerator
    @State private var testInput: String = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Test Input Section
            inputSection

            Divider()

            // Event Log Section
            eventLogSection
        }
        .background(TickerColor.surface(for: colorScheme))
        .cornerRadius(TickerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .strokeBorder(TickerColor.textTertiary(for: colorScheme).opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: TickerShadow.subtle.color,
            radius: TickerShadow.subtle.radius,
            x: TickerShadow.subtle.x,
            y: TickerShadow.subtle.y
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text("AITickerGenerator Debug")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))

                HStack(spacing: TickerSpacing.xs) {
                    Circle()
                        .fill(aiGenerator.isFoundationModelsAvailable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(aiGenerator.isFoundationModelsAvailable ? "Foundation Models Active" : "Regex Fallback")
                        .Caption2()
                        .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            // Clear button
            Button {
                aiGenerator.clearDebugEvents()
                TickerHaptics.selection()
            } label: {
                Image(systemName: "trash")
                    .font(.callout)
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .padding(TickerSpacing.sm)
                    .background(
                        Circle()
                            .fill(TickerColor.textSecondary(for: colorScheme).opacity(0.1))
                    )
            }
        }
        .padding(TickerSpacing.md)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Test Input")
                .Subheadline()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))

            // Text input with border
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .fill(TickerColor.background(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.medium)
                            .strokeBorder(TickerColor.primary.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 100)

                if testInput.isEmpty {
                    Text("e.g., Wake up at 7am every weekday")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .padding(TickerSpacing.md)
                }

                TextEditor(text: $testInput)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(TickerSpacing.sm)
                    .onChange(of: testInput) { _, newValue in
                        // Trigger parsing in background
                        aiGenerator.parseInBackground(from: newValue)
                    }
            }

            // Status indicators
            HStack(spacing: TickerSpacing.md) {
                // Parsing indicator
                if aiGenerator.isParsing {
                    HStack(spacing: TickerSpacing.xs) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(TickerColor.primary)

                        Text("Parsing...")
                            .Caption2()
                            .foregroundStyle(TickerColor.primary)
                    }
                }

                Spacer()

                // Event count
                Text("\(aiGenerator.debugEvents.count) events")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
            }
        }
        .padding(TickerSpacing.md)
    }

    // MARK: - Event Log Section

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("Event Log")
                .Subheadline()
                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                .padding(.horizontal, TickerSpacing.md)
                .padding(.top, TickerSpacing.md)

            // Event list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: TickerSpacing.xs) {
                    if aiGenerator.debugEvents.isEmpty {
                        Text("No events yet. Start typing to see parsing events.")
                            .Caption()
                            .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                            .padding(TickerSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(aiGenerator.debugEvents.reversed()) { event in
                            eventRow(event)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
            .padding(.horizontal, TickerSpacing.md)
            .padding(.bottom, TickerSpacing.md)
        }
    }

    // MARK: - Event Row

    @ViewBuilder
    private func eventRow(_ event: AIDebugEvent) -> some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
            HStack(spacing: TickerSpacing.xs) {
                // Event type emoji
                Text(event.type.rawValue)
                    .font(.caption)

                // Timestamp
                Text(event.formattedTime)
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .monospacedDigit()

                // Message
                Text(event.message)
                    .Caption()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
            }

            // Metadata if present
            if !event.metadata.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(event.metadata.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(spacing: TickerSpacing.xs) {
                            Text("•")
                                .Caption2()
                                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))

                            Text("\(key):")
                                .Caption2()
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                .fontWeight(.medium)

                            Text(value)
                                .Caption2()
                                .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                                .monospacedDigit()
                        }
                        .padding(.leading, TickerSpacing.md)
                    }
                }
            }
        }
        .padding(.vertical, TickerSpacing.xs)
        .padding(.horizontal, TickerSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.small)
                .fill(eventBackgroundColor(for: event.type))
        )
    }

    // MARK: - Helpers

    private func eventBackgroundColor(for type: AIDebugEvent.EventType) -> Color {
        switch type {
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .timing:
            return Color.purple.opacity(0.1)
        case .streaming:
            return Color.blue.opacity(0.1)
        case .parsing:
            return Color.cyan.opacity(0.1)
        case .info:
            return TickerColor.surface(for: colorScheme).opacity(0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var generator = AITickerGenerator()

    VStack {
        AITickerGeneratorDebugView(aiGenerator: generator)
            .padding()
    }
    .background(TickerColor.background(for: .light))
    .onAppear {
        generator.isDebugMode = true

        // Add some sample events
        Task {
            await generator.prepareSession()
        }
    }
}
#endif
