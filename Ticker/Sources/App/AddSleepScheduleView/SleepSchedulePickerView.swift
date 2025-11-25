//
//  SleepSchedulePickerView.swift
//  Ticker
//
//  Created by Claude Code
//  Circular 24-hour sleep schedule picker with Liquid Glass design
//

import SwiftUI
import TickerCore

struct SleepSchedulePickerView: View {
    @Binding var bedtime: TimeOfDay
    @Binding var wakeTime: TimeOfDay

    @State private var bedtimeAngle: Angle
    @State private var wakeTimeAngle: Angle
    @State private var isDraggingBedtime = false
    @State private var isDraggingWakeTime = false

    private let clockRadius: CGFloat = 120
    private let indicatorRadius: CGFloat = 20

    init(bedtime: Binding<TimeOfDay>, wakeTime: Binding<TimeOfDay>) {
        self._bedtime = bedtime
        self._wakeTime = wakeTime

        // Initialize angles from times
        let bedtimeAngle = Self.timeToAngle(bedtime.wrappedValue)
        let wakeTimeAngle = Self.timeToAngle(wakeTime.wrappedValue)

        self._bedtimeAngle = State(initialValue: bedtimeAngle)
        self._wakeTimeAngle = State(initialValue: wakeTimeAngle)
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Background clock face
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: clockRadius * 2, height: clockRadius * 2)

                // Hour tick marks
                ForEach(0..<24, id: \.self) { hour in
                    tickMark(for: hour, center: center)
                }

                // Hour labels (0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22)
                ForEach([0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22], id: \.self) { hour in
                    hourLabel(for: hour, center: center)
                }

                // Sleep duration arc (filled region between bedtime and wake time)
                sleepDurationArc(center: center)

                // Wake time ring (outer draggable ring)
                wakeTimeRing(center: center)

                // Bedtime indicator (bed icon at bedtime position)
                bedtimeIndicator(center: center)

                // Wake time indicator (alarm icon on ring)
                wakeTimeIndicator(center: center)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 400, maxHeight: 400)
    }

    // MARK: - Component Views

    private func tickMark(for hour: Int, center: CGPoint) -> some View {
        let angle = Angle(degrees: Double(hour) * 15) // 360 / 24 = 15 degrees per hour
        let startRadius = clockRadius - 10
        let endRadius = clockRadius - 5
        let isMajor = hour % 6 == 0

        return Path { path in
            let start = pointOnCircle(center: center, radius: startRadius, angle: angle)
            let end = pointOnCircle(center: center, radius: isMajor ? clockRadius : endRadius, angle: angle)
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(Color.white.opacity(isMajor ? 0.6 : 0.3), lineWidth: isMajor ? 2 : 1)
    }

    private func hourLabel(for hour: Int, center: CGPoint) -> some View {
        let angle = Angle(degrees: Double(hour) * 15)
        let labelRadius = clockRadius - 25
        let position = pointOnCircle(center: center, radius: labelRadius, angle: angle)

        return Text("\(hour)")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.7))
            .position(position)
    }

    private func sleepDurationArc(center: CGPoint) -> some View {
        let startAngle = bedtimeAngle
        let endAngle = wakeTimeAngle

        return SleepArcShape(startAngle: startAngle, endAngle: endAngle)
            .fill(Color.black.opacity(0.9))
            .frame(width: clockRadius * 2, height: clockRadius * 2)
            .position(center)
    }

    private func wakeTimeRing(center: CGPoint) -> some View {
        let outerRadius = clockRadius + 30
        let startAngle = bedtimeAngle
        let endAngle = wakeTimeAngle

        return RingArcShape(
            startAngle: startAngle,
            endAngle: endAngle,
            innerRadius: clockRadius,
            outerRadius: outerRadius
        )
        .fill(Color.gray.opacity(0.3))
        .position(center)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDraggingWakeTime = true
                    let angle = angleFromPoint(value.location, center: center)
                    wakeTimeAngle = angle
                    wakeTime = Self.angleToTime(angle)
                }
                .onEnded { _ in
                    isDraggingWakeTime = false
                }
        )
    }

    private func bedtimeIndicator(center: CGPoint) -> some View {
        let position = pointOnCircle(center: center, radius: clockRadius, angle: bedtimeAngle)

        return Image(systemName: "bed.double.fill")
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: indicatorRadius * 2, height: indicatorRadius * 2)
            .background(
                Circle()
                    .fill(Color.blue)
                    .glassEffect(.regular.interactive())
            )
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDraggingBedtime = true
                        let angle = angleFromPoint(value.location, center: center)
                        bedtimeAngle = angle
                        bedtime = Self.angleToTime(angle)
                    }
                    .onEnded { _ in
                        isDraggingBedtime = false
                    }
            )
    }

    private func wakeTimeIndicator(center: CGPoint) -> some View {
        let outerRadius = clockRadius + 30
        let position = pointOnCircle(center: center, radius: outerRadius, angle: wakeTimeAngle)

        return Image(systemName: "alarm.fill")
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: indicatorRadius * 2, height: indicatorRadius * 2)
            .background(
                Circle()
                    .fill(Color.orange)
                    .glassEffect(.regular.interactive())
            )
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDraggingWakeTime = true
                        let angle = angleFromPoint(value.location, center: center)
                        wakeTimeAngle = angle
                        wakeTime = Self.angleToTime(angle)
                    }
                    .onEnded { _ in
                        isDraggingWakeTime = false
                    }
            )
    }

    // MARK: - Helper Methods

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        // Adjust angle to start at top (0° = midnight)
        let adjustedAngle = angle.radians - .pi / 2
        return CGPoint(
            x: center.x + radius * CGFloat(cos(adjustedAngle)),
            y: center.y + radius * CGFloat(sin(adjustedAngle))
        )
    }

    private func angleFromPoint(_ point: CGPoint, center: CGPoint) -> Angle {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radians = atan2(dy, dx) + .pi / 2 // Adjust to start at top
        let degrees = radians * 180 / .pi
        return Angle(degrees: degrees >= 0 ? degrees : degrees + 360)
    }

    private static func timeToAngle(_ time: TimeOfDay) -> Angle {
        let totalMinutes = time.hour * 60 + time.minute
        let degrees = (Double(totalMinutes) / (24 * 60)) * 360
        return Angle(degrees: degrees)
    }

    private static func angleToTime(_ angle: Angle) -> TimeOfDay {
        var normalizedDegrees = angle.degrees.truncatingRemainder(dividingBy: 360)
        if normalizedDegrees < 0 {
            normalizedDegrees += 360
        }

        let totalMinutes = Int((normalizedDegrees / 360.0) * (24 * 60))
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        let roundedMinutes = (minutes / 5) * 5

        return TimeOfDay(hour: hours, minute: roundedMinutes)
    }
}

// MARK: - Custom Shapes

/// Arc shape for sleep duration (filled region between bedtime and wake time)
struct SleepArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Adjust angles to start at top (0° = midnight)
        let adjustedStart = startAngle - Angle(degrees: 90)
        let adjustedEnd = endAngle - Angle(degrees: 90)

        // Determine clockwise direction
        let clockwise = adjustedEnd.degrees > adjustedStart.degrees

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: adjustedStart,
            endAngle: adjustedEnd,
            clockwise: !clockwise
        )
        path.closeSubpath()

        return path
    }
}

/// Ring arc shape for wake time indicator ring
struct RingArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Adjust angles to start at top
        let adjustedStart = startAngle - Angle(degrees: 90)
        let adjustedEnd = endAngle - Angle(degrees: 90)

        // Determine clockwise direction
        let clockwise = adjustedEnd.degrees > adjustedStart.degrees

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: adjustedStart,
            endAngle: adjustedEnd,
            clockwise: !clockwise
        )

        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: adjustedEnd,
            endAngle: adjustedStart,
            clockwise: clockwise
        )

        path.closeSubpath()
        return path
    }
}
