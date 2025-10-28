//
//  AlarmLiveActivityPreview.swift
//  alarm
//
//  Preview for Live Activity showing different states and configurations
//

import SwiftUI
import ActivityKit
import AlarmKit
import WidgetKit

// MARK: - Mock Data

// Using the actual TickerData structure from AlarmMetadata.swift
extension TickerData {
    static func mock(title: String = "Morning Alarm", icon: String = "sun.max.fill", color: String = "#FF6B35") -> TickerData {
        TickerData(
            name: title,
            icon: icon,
            colorHex: color
        )
    }
}

// MARK: - Preview Helpers

extension AlarmLiveActivity {
    
    // Mock attributes for different scenarios
    static func mockAttributes(title: String = "Morning Alarm", icon: String = "sun.max.fill") -> AlarmAttributes<TickerData> {
        AlarmAttributes(
            presentation: mockPresentation(),
            metadata: TickerData.mock(title: title, icon: icon),
            tintColor: Color(hex: "#FF6B35") ?? .orange
        )
    }
    
    static func mockPresentation() -> AlarmPresentation {
        AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "Morning Alarm"),
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .black,
                    systemImageName: "stop.fill"
                ),
                secondaryButton: AlarmButton(
                    text: "Snooze",
                    textColor: .black,
                    systemImageName: "moon.zzz.fill"
                ),
                secondaryButtonBehavior: .custom
            ),
            countdown: AlarmPresentation.Countdown(
                title: LocalizedStringResource(stringLiteral: "Morning Alarm"),
                pauseButton: AlarmButton(
                    text: "Pause",
                    textColor: .black,
                    systemImageName: "pause.fill"
                )
            ),
            paused: AlarmPresentation.Paused(
                title: "Paused",
                resumeButton: AlarmButton(
                    text: "Resume",
                    textColor: .black,
                    systemImageName: "play.fill"
                )
            )
        )
    }
    
    // Mock states for different scenarios
    static func mockCountdownState() -> AlarmPresentationState {
        AlarmPresentationState(
            alarmID: UUID(),
            mode: .countdown(
                AlarmPresentationState.Mode
                    .Countdown(
                        totalCountdownDuration: 10,
                        previouslyElapsedDuration: 10,
                        startDate: Date(),
                        fireDate: Date().addingTimeInterval(12000)
                    )
            )
        )
    }
    
    static func mockPausedState() -> AlarmPresentationState {
        AlarmPresentationState(
            alarmID: UUID(),
            mode: .paused(
                AlarmPresentationState.Mode.Paused(
                    totalCountdownDuration: 600,
                    previouslyElapsedDuration: 300     // 10 minutes total
                )
            )
        )
    }
    
    static func mockAlertState() -> AlarmPresentationState {
        AlarmPresentationState(
            alarmID: UUID(),
            mode: .alert(.init(time: .init(hour: 10, minute: 2)))
        )
    }
}

// MARK: - Preview Views

struct AlarmLiveActivityPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Live Activity Previews")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Lock Screen Views
                    Group {
                        Text("Lock Screen Views")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 15) {
                            // Countdown State
                            AlarmLiveActivityPreview.lockScreenView(
                                attributes: AlarmLiveActivity.mockAttributes(),
                                state: AlarmLiveActivity.mockCountdownState()
                            )
                            .frame(height: 120)
                            .previewDisplayName("Countdown State")
                            
                            // Paused State
                            AlarmLiveActivityPreview.lockScreenView(
                                attributes: AlarmLiveActivity.mockAttributes(title: "Workout Timer", icon: "figure.run"),
                                state: AlarmLiveActivity.mockPausedState()
                            )
                            .frame(height: 120)
                            .previewDisplayName("Paused State")
                            
                            // Alert State
                            AlarmLiveActivityPreview.lockScreenView(
                                attributes: AlarmLiveActivity.mockAttributes(title: "Meeting Reminder", icon: "calendar"),
                                state: AlarmLiveActivity.mockAlertState()
                            )
                            .frame(height: 120)
                            .previewDisplayName("Alert State")
                        }
                    }
                    
                    // Dynamic Island Views
                    Group {
                        Text("Dynamic Island Views")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 15) {
                            // Expanded Dynamic Island - Countdown
                            AlarmLiveActivityPreview.expandedDynamicIsland(
                                attributes: AlarmLiveActivity.mockAttributes(),
                                state: AlarmLiveActivity.mockCountdownState()
                            )
                            .frame(height: 80)
                            .previewDisplayName("Expanded - Countdown")
                            
                            // Expanded Dynamic Island - Paused
                            AlarmLiveActivityPreview.expandedDynamicIsland(
                                attributes: AlarmLiveActivity.mockAttributes(title: "Study Session", icon: "book.fill"),
                                state: AlarmLiveActivity.mockPausedState()
                            )
                            .frame(height: 80)
                            .previewDisplayName("Expanded - Paused")
                            
                            // Minimal Dynamic Island
                            AlarmLiveActivityPreview.minimalDynamicIsland(
                                attributes: AlarmLiveActivity.mockAttributes(),
                                state: AlarmLiveActivity.mockCountdownState()
                            )
                            .frame(height: 40)
                            .previewDisplayName("Minimal")
                        }
                    }
                    
                    // Component Previews
                    Group {
                        Text("Component Previews")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 15) {
                            // Alarm Controls
                            AlarmControls(
                                presentation: AlarmLiveActivity.mockPresentation(),
                                state: AlarmLiveActivity.mockCountdownState()
                            )
                            .previewDisplayName("Alarm Controls - Countdown")
                            
                            AlarmControls(
                                presentation: AlarmLiveActivity.mockPresentation(),
                                state: AlarmLiveActivity.mockPausedState()
                            )
                            .previewDisplayName("Alarm Controls - Paused")
                            
                            // Progress View
                            AlarmProgressView(
                                tickerIcon: "sun.max.fill",
                                mode: AlarmLiveActivity.mockCountdownState().mode,
                                tint: .orange
                            )
                            .previewDisplayName("Progress View - Countdown")
                            
                            AlarmProgressView(
                                tickerIcon: "moon.fill",
                                mode: AlarmLiveActivity.mockPausedState().mode,
                                tint: .blue
                            )
                            .previewDisplayName("Progress View - Paused")
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview Extensions

extension AlarmLiveActivityPreview {
    
    // Lock Screen View Preview
    static func lockScreenView(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: TickerSpacing.lg) {
            HStack(alignment: .top) {
                // Alarm Title
                VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                    Text(attributes.metadata?.name ?? "Alarm")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(TickerColor.absoluteWhite)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    Text("Next: 8:00 AM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TickerColor.absoluteWhite.opacity(0.8))
                }
                
                Spacer()
                
                // Category Icon
                Image(systemName: attributes.metadata?.icon ?? "alarm")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: attributes.metadata?.colorHex ?? "#FF6B35") ?? .orange)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // Bottom View with Countdown and Controls
            HStack(spacing: TickerSpacing.lg) {
                VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                    // Countdown Display
                    Text(countdownText(for: state))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(stateColor(for: state.mode))
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
                    
                    // Status Indicator
                    HStack(spacing: TickerSpacing.sm) {
                        Circle()
                            .fill(stateColor(for: state.mode))
                            .frame(width: 12, height: 12)
                            .scaleEffect(isCountdownMode(state.mode) ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
                        
                        Text(statusText(for: state.mode))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TickerColor.absoluteWhite)
                    }
                }
                
                Spacer()
                
                // Mock Controls
                HStack(spacing: TickerSpacing.xs) {
                    Button(action: {}) {
                        HStack(spacing: TickerSpacing.xs) {
                            Image(systemName: controlIcon(for: state.mode))
                                .font(.system(size: 16, weight: .bold))
                            Text(controlText(for: state.mode))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(TickerColor.absoluteWhite)
                        .padding(.horizontal, TickerSpacing.lg)
                        .padding(.vertical, TickerSpacing.md)
                        .background(
                            Capsule()
                                .fill(controlColor(for: state.mode))
                        )
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: TickerSpacing.xs) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Stop")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(TickerColor.absoluteWhite)
                        .padding(.horizontal, TickerSpacing.lg)
                        .padding(.vertical, TickerSpacing.md)
                        .background(
                            Capsule()
                                .fill(TickerColor.danger)
                        )
                    }
                }
            }
        }
        .padding(.all, TickerSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.large)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.large)
                        .strokeBorder(
                            LinearGradient(
                                colors: [stateColor(for: state.mode).opacity(0.6), stateColor(for: state.mode).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: stateColor(for: state.mode).opacity(0.4),
            radius: TickerShadow.elevated.radius + 4,
            x: TickerShadow.elevated.x,
            y: TickerShadow.elevated.y + 2
        )
    }
    
    // Expanded Dynamic Island Preview
    static func expandedDynamicIsland(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text(countdownText(for: state))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(stateColor(for: state.mode))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(attributes.metadata?.name ?? "Alarm")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerColor.absoluteWhite)
                    .lineLimit(1)
            }
            
            Spacer()
            
            AlarmProgressView(
                tickerIcon: attributes.metadata?.icon,
                mode: state.mode,
                tint: stateColor(for: state.mode)
            )
        }
        .padding(.horizontal, TickerSpacing.lg)
        .padding(.vertical, TickerSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: TickerRadius.medium)
                        .strokeBorder(stateColor(for: state.mode).opacity(0.6), lineWidth: 1)
                )
        )
    }
    
    // Minimal Dynamic Island Preview
    static func minimalDynamicIsland(attributes: AlarmAttributes<TickerData>, state: AlarmPresentationState) -> some View {
        ZStack {
            Circle()
                .fill(stateColor(for: state.mode).opacity(0.15))
                .frame(width: 24, height: 24)
                .scaleEffect(isCountdownMode(state.mode) ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCountdownMode(state.mode))
            
            AlarmProgressView(
                tickerIcon: attributes.metadata?.icon,
                mode: state.mode,
                tint: stateColor(for: state.mode)
            )
        }
    }
    
    // Helper functions
    private static func isCountdownMode(_ mode: AlarmPresentationState.Mode) -> Bool {
        switch mode {
        case .countdown:
            return true
        case .paused, .alert:
            return false
        @unknown default:
            return false
        }
    }
    
    private static func stateColor(for mode: AlarmPresentationState.Mode) -> Color {
        switch mode {
        case .countdown:
            return TickerColor.running
        case .paused:
            return TickerColor.paused
        case .alert:
            return TickerColor.alerting
        @unknown default:
            return TickerColor.disabled
        }
    }
    
    private static func countdownText(for state: AlarmPresentationState) -> String {
        switch state.mode {
        case .countdown(let countdown):
            let remaining = Int(countdown.fireDate.timeIntervalSinceNow)
            let minutes = remaining / 60
            let seconds = remaining % 60
            return String(format: "%02d:%02d", minutes, seconds)
        case .paused(let paused):
            let remaining = paused.totalCountdownDuration - paused.previouslyElapsedDuration
            let minutes = remaining / 60
            let seconds = remaining
            return String(format: "%02d:%02d", minutes, seconds)
        case .alert:
            return "00:00"
        @unknown default:
            return "00:00"
        }
    }
    
    private static func statusText(for mode: AlarmPresentationState.Mode) -> String {
        switch mode {
        case .countdown:
            return "Running"
        case .paused:
            return "Paused"
        case .alert:
            return "Alerting"
        @unknown default:
            return "Unknown"
        }
    }
    
    private static func controlIcon(for mode: AlarmPresentationState.Mode) -> String {
        switch mode {
        case .countdown:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .alert:
            return "stop.fill"
        @unknown default:
            return "stop.fill"
        }
    }
    
    private static func controlText(for mode: AlarmPresentationState.Mode) -> String {
        switch mode {
        case .countdown:
            return "Pause"
        case .paused:
            return "Resume"
        case .alert:
            return "Stop"
        @unknown default:
            return "Stop"
        }
    }
    
    private static func controlColor(for mode: AlarmPresentationState.Mode) -> Color {
        switch mode {
        case .countdown:
            return TickerColor.paused
        case .paused:
            return TickerColor.running
        case .alert:
            return TickerColor.danger
        @unknown default:
            return TickerColor.danger
        }
    }
}


// MARK: - Component Previews (Regular SwiftUI Previews)

#Preview("Components - Controls") {
    VStack(spacing: 20) {
        AlarmControls(
            presentation: AlarmLiveActivity.mockPresentation(),
            state: AlarmLiveActivity.mockCountdownState()
        )
        
        AlarmControls(
            presentation: AlarmLiveActivity.mockPresentation(),
            state: AlarmLiveActivity.mockPausedState()
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Components - Progress") {
    HStack(spacing: 30) {
        AlarmProgressView(
            tickerIcon: "sun.max.fill",
            mode: AlarmLiveActivity.mockCountdownState().mode,
            tint: .orange
        )
        
        AlarmProgressView(
            tickerIcon: "moon.fill",
            mode: AlarmLiveActivity.mockPausedState().mode,
            tint: .blue
        )
        
        AlarmProgressView(
            tickerIcon: "bell.fill",
            mode: AlarmLiveActivity.mockAlertState().mode,
            tint: .red
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Full Preview Showcase") {
    AlarmLiveActivityPreview()
}
