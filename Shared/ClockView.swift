//
//  ClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct ClockView: View {
    @Environment(\.colorScheme) private var colorScheme

    struct MinuteMark: Identifiable {
        var id: Double {
            angle
        }
        var angle: Double
    }


    struct HourMark: Identifiable {
        var id: Int
        var time: Int?
        var angle: Double
        var textAngle: Double?
    }

    var upcomingAlarms: [UpcomingAlarmPresentation]
    var shouldAnimateAlarms: Bool = false
    @State private var currentTime = Date()
    @State private var alarmAnimationStates: [UUID: Bool] = [:]
    
    let hourMarks: [HourMark] = [
        HourMark(id: 0, time: 12, angle: 0, textAngle: 0),
        HourMark(id: 1, time: nil, angle: 30, textAngle: nil),
        HourMark(id: 2, time: nil, angle: 60, textAngle: nil),
        HourMark(id: 3, time: 3, angle: 90, textAngle: 270),
        HourMark(id: 4, time: nil, angle: 120, textAngle: nil),
        HourMark(id: 5, time: nil, angle: 150, textAngle: nil),
        HourMark(id: 6, time: 6, angle: 180, textAngle: 180),
        HourMark(id: 7, time: nil, angle: 210, textAngle: nil),
        HourMark(id: 8, time: nil, angle: 240, textAngle: nil),
        HourMark(id: 9, time: 9, angle: 270, textAngle: 90),
        HourMark(id: 10, time: nil, angle: 300, textAngle: nil),
        HourMark(id: 11, time: nil, angle: 330, textAngle: nil),
    ]
    
    let minuteMarks: [MinuteMark] = stride(from: 0, through: 360, by: 3).map { angle in
        MinuteMark(angle: Double(angle))
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let markOffset = radius * 0.95
                let handLength = radius
                
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: timeline.date)
                let minute = calendar.component(.minute, from: timeline.date)
                let second = calendar.component(.second, from: timeline.date)
                
                let hourAngle = Double(hour % 12) * 30 + Double(minute) * 0.5
                let minuteAngle = Double(minute) * 6
                let secondAngle = Double(second) * 6
                
                ZStack {
                    // Enhanced clock face with glassmorphism
                    ZStack {
                                // Base gradient
                                LinearGradient(
                                    colors: [
                                        Color(.secondarySystemBackground),
                                        Color(.tertiarySystemBackground)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                // Glassmorphism overlay
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                    .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(.label).opacity(0.1), radius: 20, x: 0, y: 8)
                        .shadow(color: Color(.label).opacity(0.05), radius: 5, x: 0, y: 2)
                        .shadow(color: Color(.label).opacity(0.02), radius: 1, x: 0, y: 1)
                    
                    ForEach(hourMarks) { hourmark in
                        Rectangle()
                            .fill(hourmark.time != nil ? Color(.label) : Color(.secondaryLabel))
                            .frame(
                                width: hourmark.time != nil ? 2 : 1,
                                height: hourmark.time != nil ? radius * 0.12 : radius * 0.08
                            )
                            .offset(y: -markOffset)
                            .rotationEffect(Angle(degrees: hourmark.angle))
                        
                        if let time = hourmark.time, let textAngle = hourmark.textAngle {
                            Text("\(time)")
                                .rotationEffect(Angle(degrees: textAngle))
                                .Title2()
                                .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                                .offset(y: -radius * 0.7)
                                .rotationEffect(Angle(degrees: hourmark.angle))
                        }
                    }
                    
                    ForEach(minuteMarks) { hourmark in
                        Rectangle()
                            .fill(Color(.tertiaryLabel).opacity(0.5))
                            .frame(
                                width: 1,
                                height: radius * 0.04
                            )
                            .offset(y: -markOffset)
                            .rotationEffect(Angle(degrees: hourmark.angle))
                    }
                    
                    ForEach(Array(upcomingAlarms.enumerated()), id: \.element.id) { index, event in
                        VStack(spacing: .zero) {
                            // Enhanced alarm indicator
                            ZStack {
                                // Background capsule with gradient
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                event.color.opacity(0.9),
                                                event.color.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: handLength * 0.18, height: handLength * 0.6)
                                    .shadow(color: event.color.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                // Icon and text
                                VStack(spacing: 2) {
                                    Image(systemName: event.icon)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    Text(event.displayName)
                                        .font(.system(size: 8, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                }
                                .rotationEffect(Angle(degrees: event.angle > 180 ? 90 : -90))
                            }
                            
                            // Connection line to clock face
                            Rectangle()
                                .fill(event.color.opacity(0.6))
                                .frame(width: 2, height: handLength * 0.15)
                                .offset(y: -handLength * 0.075)
                        }
                        .offset(y: -handLength * 0.45)
                        .rotationEffect(Angle(degrees: event.angle))
                        .scaleEffect(alarmAnimationStates[event.id] == true ? 1.0 : 0.1)
                        .opacity(alarmAnimationStates[event.id] == true ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                            .delay(Double(index) * 0.1),
                            value: alarmAnimationStates[event.id]
                        )
                    }
                    
                    // Enhanced Hour Hand
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TickerColor.textPrimary(for: colorScheme),
                                    TickerColor.textPrimary(for: colorScheme).opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 5, height: radius * 0.5)
                        .offset(y: -radius * 0.25)
                        .rotationEffect(Angle(degrees: hourAngle))
                        .shadow(color: TickerColor.textPrimary(for: colorScheme).opacity(0.4), radius: 3, x: 0, y: 2)
                    
                    // Enhanced Minute Hand
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TickerColor.textPrimary(for: colorScheme),
                                    TickerColor.textPrimary(for: colorScheme).opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: radius * 0.7)
                        .offset(y: -radius * 0.35)
                        .rotationEffect(Angle(degrees: minuteAngle))
                        .shadow(color: TickerColor.textPrimary(for: colorScheme).opacity(0.4), radius: 3, x: 0, y: 2)
                    
                    // Enhanced Second Hand
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TickerColor.primary,
                                    TickerColor.accent
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: radius * 0.8)
                        .offset(y: -radius * 0.4)
                        .rotationEffect(Angle(degrees: secondAngle))
                        .animation(.none, value: secondAngle)
                        .shadow(color: TickerColor.primary.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    // Enhanced center dot
                    ZStack {
                        Circle()
                            .fill(TickerColor.primary)
                            .frame(width: radius * 0.04, height: radius * 0.04)
                            .shadow(color: TickerColor.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: radius * 0.02, height: radius * 0.02)
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.width,
                    alignment: .center
                )
            }
        }
        .onChange(of: shouldAnimateAlarms) { _, newValue in
            if newValue {
                // Initialize all alarm animation states to false
                for alarm in upcomingAlarms {
                    alarmAnimationStates[alarm.id] = false
                }
                
                // Trigger staggered animation
                for (index, alarm) in upcomingAlarms.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                        alarmAnimationStates[alarm.id] = true
                    }
                }
            }
        }
        .onChange(of: upcomingAlarms) { _, newAlarms in
            // If we have alarms and should animate, trigger animation
            if !newAlarms.isEmpty && shouldAnimateAlarms {
                // Initialize all alarm animation states to false
                for alarm in newAlarms {
                    alarmAnimationStates[alarm.id] = false
                }
                
                // Trigger staggered animation
                for (index, alarm) in newAlarms.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                        alarmAnimationStates[alarm.id] = true
                    }
                }
            }
        }
        .onAppear {
            // Initialize animation states when view appears
            for alarm in upcomingAlarms {
                alarmAnimationStates[alarm.id] = shouldAnimateAlarms
            }
        }
    }
}

#Preview("Empty Clock") {
    ClockView(upcomingAlarms: [], shouldAnimateAlarms: false)
        .padding()
        .background(Color.black)
}

#Preview("Multiple Alarms") {
    ClockView(upcomingAlarms: [
        // 12:00 PM - Should be at top (0°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Noon",
            icon: "sun.max.fill",
            color: .yellow,
            nextAlarmTime: Date(),
            scheduleType: .daily,
            hour: 12,
            minute: 0,
            hasCountdown: false,
            tickerDataTitle: nil
        ),
        // 3:00 PM - Should be at right (90°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Mid Afternoon",
            icon: "cup.and.saucer.fill",
            color: .orange,
            nextAlarmTime: Date(),
            scheduleType: .daily,
            hour: 15,
            minute: 0,
            hasCountdown: true,
            tickerDataTitle: "Coffee Break"
        ),
        // 6:00 PM - Should be at bottom (180°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Dinner",
            icon: "fork.knife",
            color: .red,
            nextAlarmTime: Date(),
            scheduleType: .daily,
            hour: 18,
            minute: 0,
            hasCountdown: false,
            tickerDataTitle: nil
        ),
        // 9:00 PM - Should be at left (270°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Bedtime",
            icon: "bed.double.fill",
            color: .purple,
            nextAlarmTime: Date(),
            scheduleType: .daily,
            hour: 21,
            minute: 0,
            hasCountdown: false,
            tickerDataTitle: nil
        ),
        // 12:30 AM - Should be slightly past top (15°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Midnight Snack",
            icon: "moon.stars.fill",
            color: .blue,
            nextAlarmTime: Date(),
            scheduleType: .oneTime,
            hour: 0,
            minute: 30,
            hasCountdown: false,
            tickerDataTitle: nil
        ),
        // 6:30 AM - Should be at bottom + offset (195°)
        UpcomingAlarmPresentation(
            id: UUID(),
            displayName: "Morning Run",
            icon: "figure.run",
            color: .green,
            nextAlarmTime: Date(),
            scheduleType: .daily,
            hour: 6,
            minute: 30,
            hasCountdown: true,
            tickerDataTitle: "Exercise"
        )
    ], shouldAnimateAlarms: false)
    .padding()
    .background(Color.clear)
}
