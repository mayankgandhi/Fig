//
//  ClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI
import WalnutDesignSystem

struct ClockView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    struct TimeBlock: Identifiable {
        let id: UUID
        let city: String
        let hour: Int
        let minute: Int
        let color: Color

        var angle: Double {
            // Convert to 12-hour format for display
            let hour12 = hour % 12
            // Calculate angle: 0° at 12, 90° at 3, 180° at 6, 270° at 9
            // Each hour = 30°, each minute = 0.5°
            return Double(hour12) * 30.0 + Double(minute) * 0.5
        }

        var timeString: String {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }
    
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
    
    var events: [TimeBlock]

    @State private var currentTime = Date()

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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemBackground),
                                Color(.tertiarySystemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color(.label).opacity(0.05), radius: 20, x: 0, y: 8)
                    .shadow(color: Color(.label).opacity(0.03), radius: 5, x: 0, y: 2)

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
                            .cabinetTitle2()
                            .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
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

                // Hour Hand
                RoundedRectangle(cornerRadius: 2)
                    .fill(TickerColors.textPrimary(for: colorScheme))
                    .frame(width: 4, height: radius * 0.5)
                    .offset(y: -radius * 0.25)
                    .rotationEffect(Angle(degrees: hourAngle))
                    .shadow(color: TickerColors.textPrimary(for: colorScheme).opacity(0.3), radius: 2, x: 0, y: 1)

                // Minute Hand
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(TickerColors.textPrimary(for: colorScheme))
                    .frame(width: 3, height: radius * 0.7)
                    .offset(y: -radius * 0.35)
                    .rotationEffect(Angle(degrees: minuteAngle))
                    .shadow(color: TickerColors.textPrimary(for: colorScheme).opacity(0.3), radius: 2, x: 0, y: 1)

                // Second Hand
                RoundedRectangle(cornerRadius: 1)
                    .fill(TickerColors.primary)
                    .frame(width: 1.5, height: radius * 0.8)
                    .offset(y: -radius * 0.4)
                    .rotationEffect(Angle(degrees: secondAngle))
                    .animation(TickerAnimation.quick, value: secondAngle)

                ForEach(events) { event in
                    VStack(spacing: .zero) {

                        HStack(spacing: TickerSpacing.xxs) {
                            Image(systemName: "alarm")
                                .font(.system(size: 10, weight: .light, design: .rounded))
                                .foregroundColor(TickerColors.textPrimary(for: colorScheme))
                            Text(event.city)
                                .cabinetFootnote()
                                .textCase(.uppercase)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(TickerColors.textPrimary(for: colorScheme))
                        }
                        .padding(.horizontal, TickerSpacing.xs)
                        .rotationEffect(Angle(degrees: event.angle > 180 ? 90 : -90))
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.small)
                                .fill(event.color.opacity(0.5))
                                .frame(width: handLength * 0.15, height: handLength*(3/4))
                        )

                    }
                    .offset(y: -handLength * 0.37)
                    .rotationEffect(Angle(degrees: event.angle))
                }

                Circle()
                    .fill(TickerColors.primary)
                    .frame(width: radius * 0.02, height: radius * 0.02)
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.width,
                    alignment: .center
                )
            }
        }
    }
}

#Preview {
    ClockView(events: [
        ClockView.TimeBlock(
            id: UUID(),
            city: "Los Angeles",
            hour: 1,
            minute: 47,
            color: .black
        ),
        ClockView.TimeBlock(
            id: UUID(),
            city: "Tokyo",
            hour: 4,
            minute: 47,
            color: .gray
        ),
        ClockView.TimeBlock(
            id: UUID(),
            city: "Yerevan",
            hour: 11,
            minute: 47,
            color: .red
        ),
        
        ClockView.TimeBlock(
            id: UUID(),
            city: "Paris",
            hour: 9,
            minute: 47,
            color: .blue
        )
    ])
    .padding()
}
