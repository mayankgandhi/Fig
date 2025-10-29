//
//  IntroAnimation.swift
//  Ticker
//
//  Created by Mayank Gandhi on 14/10/25.
//

import SwiftUI
import TickerCore
// MARK: - Dialogue Message Model

struct DialogueMessage: Identifiable, Equatable {
    let id = UUID()
    let prompt: String
    let text: String
    let icon: String
    let color: Color
    let hour: Int
    let minute: Int

    var angle: Double {
        let hour12 = hour % 12
        return Double(hour12) * 30.0 + Double(minute) * 0.5
    }

    var alarmPresentation: UpcomingAlarmPresentation {
        // Create a date for today with the specified hour and minute
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = hour
        components.minute = minute
        
        let alarmDate = calendar.date(from: components) ?? now
        
        return UpcomingAlarmPresentation(
            baseAlarmId: id,
            displayName: text,
            icon: icon,
            color: color,
            nextAlarmTime: alarmDate,
            scheduleType: .daily,
            hour: hour,
            minute: minute,
            hasCountdown: false,
            tickerDataTitle: nil
        )
    }
}

// MARK: - IntroAnimation View

struct IntroAnimation: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentMessageIndex = 0
    @State private var showingMessage = false
    @State private var messageScale: CGFloat = 0.8
    @State private var messageOpacity: Double = 0
    @State private var messageOffset: CGSize = .zero
    @State private var iconScale: CGFloat = 1.0
    @State private var scheduledAlarms: [UpcomingAlarmPresentation] = []
    @State private var showClock = false
    @State private var highlightedAlarmId: UUID?

    let onComplete: () -> Void

    private let messages: [DialogueMessage] = [
        DialogueMessage(
            prompt: "Finish the dishes before bed",
            text: "Dishes",
            icon: "drop.fill",
            color: .blue,
            hour: 18,
            minute: 30
        ),
        DialogueMessage(
            prompt: "Call mom tonight",
            text: "Call Mom",
            icon: "phone.fill",
            color: .green,
            hour: 15,
            minute: 0
        ),
        DialogueMessage(
            prompt: "Take medication after dinner (don't forget!)",
            text: "Medication",
            icon: "cross.case.fill",
            color: .red,
            hour: 20,
            minute: 0
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                TickerColor.liquidGlassGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top space for dialogues - reduced
                    Spacer()
                        .frame(height: geometry.size.height * 0.08)

                    // App Icon section - scaled down
                    ZStack {
                        // App Icon - smaller
                        Image("AppIconImage")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(
                                color: TickerShadow.elevated.color,
                                radius: TickerShadow.elevated.radius,
                                x: TickerShadow.elevated.x,
                                y: TickerShadow.elevated.y
                            )
                            .scaleEffect(iconScale)
                            .animation(TickerAnimation.spring, value: iconScale)

                        // Dialogue callout - positioned above icon with proper visibility
                        if showingMessage && currentMessageIndex < messages.count {
                            DialogueCallout(message: messages[currentMessageIndex])
                                .scaleEffect(messageScale)
                                .opacity(messageOpacity)
                                .offset(messageOffset)
                                .frame(maxWidth: geometry.size.width * 0.75)
                        }
                    }
                    .frame(height: min(220, geometry.size.height * 0.30))

                    // Spacing between icon and clock
                    Spacer()
                        .frame(height: TickerSpacing.md)

                    // Clock View - constrained size
                    if showClock {
                        VStack(spacing: TickerSpacing.sm) {
                            ClockFaceView(
                                currentDate: Date(),
                                upcomingAlarms: scheduledAlarms,
                                shouldAnimateAlarms: true
                            )
                                .frame(height: min(280, geometry.size.height * 0.45))
                                .padding(.horizontal, TickerSpacing.lg)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.8).combined(with: .opacity)
                                    )
                                )

                        }
                        .padding(.horizontal, TickerSpacing.md)
                    }

                    // Bottom spacer
                    Spacer()
                        .frame(height: geometry.size.height * 0.08)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation Logic

    private func startAnimation() {
        // Show clock early so users can see where alarms will land
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                showClock = true
            }
        }

        // Start first message after clock appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showNextMessage()
        }
    }

    private func showNextMessage() {
        guard currentMessageIndex < messages.count else {
            // All messages completed - call completion handler
            onComplete()
            return
        }

        let currentMessage = messages[currentMessageIndex]

        // Reset state for new message
        messageScale = 0.8
        messageOpacity = 0
        messageOffset = CGSize(width: 0, height: -120) // Position above icon

        // Phase 1: Dialogue appears above icon (1.2s)
        showingMessage = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            messageScale = 1.0
            messageOpacity = 1.0
        }

        // Phase 2: Hold for reading (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // Icon anticipation - slight squeeze
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                iconScale = 0.92
            }
        }

        // Phase 3: Message enters icon (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                messageScale = 0.2
                messageOpacity = 0
                messageOffset = CGSize(width: 0, height: 0) // Move to icon center
                iconScale = 1.08
            }

            TickerHaptics.impact(.medium)
        }

        // Phase 4: Icon returns to normal, alarm appears on clock (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                iconScale = 1.0
            }

            // Briefly highlight where alarm will appear
            showingMessage = false

            // Add alarm to clock with highlight effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scheduledAlarms.append(currentMessage.alarmPresentation)
                    highlightedAlarmId = currentMessage.id
                }
                TickerHaptics.selection()
            }
        }

        // Phase 5: Move to next message (0.8s pause)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            highlightedAlarmId = nil
            currentMessageIndex += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNextMessage()
            }
        }
    }
}



// MARK: - Dialogue Callout Component

struct DialogueCallout: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: DialogueMessage

    var body: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.xs) {
            // Icon and prompt text
            HStack(alignment: .top, spacing: TickerSpacing.sm) {
                Image(systemName: message.icon)
                    .SmallText()
                    .foregroundStyle(message.color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(message.color.opacity(0.15))
                    )

                Text(message.prompt)
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.md)
        .background(
            ZStack {
                // Main glass background
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(.ultraThinMaterial)

                // Gradient overlay for depth
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                message.color.opacity(0.05),
                                Color.clear,
                                message.color.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Colored border
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                message.color.opacity(0.6),
                                message.color.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .shadow(color: message.color.opacity(0.25), radius: 16, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        // Speech bubble pointer
        .overlay(alignment: .bottom) {
            CalloutPointer(color: message.color)
                .offset(y: 12)
        }
    }
}

// MARK: - Callout Pointer

struct CalloutPointer: View {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color

    var body: some View {
        ZStack {
            // Main triangle
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 5, y: 12))
                path.closeSubpath()
            }
            .fill(.ultraThinMaterial)

            // Gradient overlay
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 5, y: 12))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Border
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 5, y: 12))
                path.addLine(to: CGPoint(x: 10, y: 0))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(0.6),
                        color.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
        }
        .frame(width: 10, height: 12)
    }
}

#Preview {
    IntroAnimation(onComplete: {
        print("Animation completed")
    })
}
