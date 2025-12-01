//
//  SleepSchedulePickerView.swift
//  Ticker
//
//  Created by Claude Code
//  Circular 24-hour sleep schedule picker with Liquid Glass design
//

import SwiftUI
import TickerCore
import UIKit

struct SleepSchedulePickerView: View {
    @Binding var bedtime: TimeOfDay
    @Binding var wakeTime: TimeOfDay

    @State private var bedtimeAngle: Angle
    @State private var wakeTimeAngle: Angle
    @State private var isDraggingBedtime = false
    @State private var isDraggingWakeTime = false
    
    // Haptic feedback state
    @State private var lastBedtimeHour: Int = -1
    @State private var lastWakeTimeHour: Int = -1
    @State private var wasConstrained = false
    @State private var hapticGenerator: UIImpactFeedbackGenerator?
    @State private var notificationGenerator: UINotificationFeedbackGenerator?
    @State private var lastHapticTime: Date = Date()

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
        // Calculate which path is shorter (the actual sleep duration)
        let (startAngle, endAngle) = calculateShortestArc(from: bedtimeAngle, to: wakeTimeAngle)

        return SleepArcShape(startAngle: startAngle, endAngle: endAngle)
            .fill(Color.black.opacity(0.9))
            .frame(width: clockRadius * 2, height: clockRadius * 2)
            .position(center)
    }

    private func wakeTimeRing(center: CGPoint) -> some View {
        let outerRadius = clockRadius + 30
        // Calculate which path is shorter (the actual sleep duration)
        let (startAngle, endAngle) = calculateShortestArc(from: bedtimeAngle, to: wakeTimeAngle)

        return RingArcShape(
            startAngle: startAngle,
            endAngle: endAngle,
            innerRadius: clockRadius,
            outerRadius: outerRadius
        )
        .fill(Color.gray.opacity(0.3))
        .position(center)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDraggingWakeTime {
                        // Start of drag - prepare haptics
                        isDraggingWakeTime = true
                        hapticGenerator = UIImpactFeedbackGenerator(style: .light)
                        hapticGenerator?.prepare()
                        notificationGenerator = UINotificationFeedbackGenerator()
                        notificationGenerator?.prepare()
                        lastWakeTimeHour = wakeTime.hour
                        wasConstrained = false
                    }
                    
                    let angle = angleFromPoint(value.location, center: center)
                    let newWakeTime = Self.angleToTime(angle)
                    
                    // Check if we passed an hour marker
                    let currentHour = newWakeTime.hour
                    if currentHour != lastWakeTimeHour {
                        hapticGenerator?.impactOccurred(intensity: 0.6)
                        lastWakeTimeHour = currentHour
                    } else {
                        // Continuous subtle feedback during movement
                        hapticGenerator?.impactOccurred(intensity: 0.3)
                    }
                    
                    // Constrain to max 12 hours sleep duration
                    let constrainedTimes = constrainSleepDuration(
                        bedtime: bedtime,
                        wakeTime: newWakeTime,
                        maxHours: 12
                    )
                    
                    // Check if constraint was applied
                    let isNowConstrained = constrainedTimes.bedtime != bedtime || constrainedTimes.wakeTime != newWakeTime
                    if isNowConstrained && !wasConstrained {
                        // Hit the 12-hour limit - stronger haptic
                        notificationGenerator?.notificationOccurred(.warning)
                        wasConstrained = true
                    }
                    
                    bedtime = constrainedTimes.bedtime
                    wakeTime = constrainedTimes.wakeTime
                    bedtimeAngle = Self.timeToAngle(bedtime)
                    wakeTimeAngle = Self.timeToAngle(wakeTime)
                }
                .onEnded { _ in
                    isDraggingWakeTime = false
                    // Final haptic on release
                    hapticGenerator?.impactOccurred(intensity: 0.8)
                    hapticGenerator = nil
                    notificationGenerator = nil
                    lastWakeTimeHour = -1
                    wasConstrained = false
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
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDraggingBedtime {
                            // Start of drag - prepare haptics
                            isDraggingBedtime = true
                            hapticGenerator = UIImpactFeedbackGenerator(style: .light)
                            hapticGenerator?.prepare()
                            notificationGenerator = UINotificationFeedbackGenerator()
                            notificationGenerator?.prepare()
                            lastBedtimeHour = bedtime.hour
                            wasConstrained = false
                            lastHapticTime = Date()
                        }
                        
                        let angle = angleFromPoint(value.location, center: center)
                        let newBedtime = Self.angleToTime(angle)
                        
                        // Check if we passed an hour marker
                        let currentHour = newBedtime.hour
                        if currentHour != lastBedtimeHour {
                            hapticGenerator?.impactOccurred(intensity: 0.6)
                            lastBedtimeHour = currentHour
                            lastHapticTime = Date()
                        } else {
                            // Continuous subtle feedback during movement (throttled to ~30ms intervals)
                            let now = Date()
                            if now.timeIntervalSince(lastHapticTime) > 0.03 {
                                hapticGenerator?.impactOccurred(intensity: 0.25)
                                lastHapticTime = now
                            }
                        }
                        
                        // Constrain to max 12 hours sleep duration
                        let constrainedTimes = constrainSleepDuration(
                            bedtime: newBedtime,
                            wakeTime: wakeTime,
                            maxHours: 12
                        )
                        
                        // Check if constraint was applied
                        let isNowConstrained = constrainedTimes.bedtime != newBedtime || constrainedTimes.wakeTime != wakeTime
                        if isNowConstrained && !wasConstrained {
                            // Hit the 12-hour limit - stronger haptic
                            notificationGenerator?.notificationOccurred(.warning)
                            wasConstrained = true
                        }
                        
                        bedtime = constrainedTimes.bedtime
                        wakeTime = constrainedTimes.wakeTime
                        bedtimeAngle = Self.timeToAngle(bedtime)
                        wakeTimeAngle = Self.timeToAngle(wakeTime)
                    }
                    .onEnded { _ in
                        isDraggingBedtime = false
                        // Final haptic on release
                        hapticGenerator?.impactOccurred(intensity: 0.8)
                        hapticGenerator = nil
                        notificationGenerator = nil
                        lastBedtimeHour = -1
                        wasConstrained = false
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
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDraggingWakeTime {
                            // Start of drag - prepare haptics
                            isDraggingWakeTime = true
                            hapticGenerator = UIImpactFeedbackGenerator(style: .light)
                            hapticGenerator?.prepare()
                            notificationGenerator = UINotificationFeedbackGenerator()
                            notificationGenerator?.prepare()
                            lastWakeTimeHour = wakeTime.hour
                            wasConstrained = false
                            lastHapticTime = Date()
                        }
                        
                        let angle = angleFromPoint(value.location, center: center)
                        let newWakeTime = Self.angleToTime(angle)
                        
                        // Check if we passed an hour marker
                        let currentHour = newWakeTime.hour
                        if currentHour != lastWakeTimeHour {
                            hapticGenerator?.impactOccurred(intensity: 0.6)
                            lastWakeTimeHour = currentHour
                            lastHapticTime = Date()
                        } else {
                            // Continuous subtle feedback during movement (throttled to ~30ms intervals)
                            let now = Date()
                            if now.timeIntervalSince(lastHapticTime) > 0.03 {
                                hapticGenerator?.impactOccurred(intensity: 0.25)
                                lastHapticTime = now
                            }
                        }
                        
                        // Constrain to max 12 hours sleep duration
                        let constrainedTimes = constrainSleepDuration(
                            bedtime: bedtime,
                            wakeTime: newWakeTime,
                            maxHours: 12
                        )
                        
                        // Check if constraint was applied
                        let isNowConstrained = constrainedTimes.bedtime != bedtime || constrainedTimes.wakeTime != newWakeTime
                        if isNowConstrained && !wasConstrained {
                            // Hit the 12-hour limit - stronger haptic
                            notificationGenerator?.notificationOccurred(.warning)
                            wasConstrained = true
                        }
                        
                        bedtime = constrainedTimes.bedtime
                        wakeTime = constrainedTimes.wakeTime
                        bedtimeAngle = Self.timeToAngle(bedtime)
                        wakeTimeAngle = Self.timeToAngle(wakeTime)
                    }
                    .onEnded { _ in
                        isDraggingWakeTime = false
                        // Final haptic on release
                        hapticGenerator?.impactOccurred(intensity: 0.8)
                        hapticGenerator = nil
                        notificationGenerator = nil
                        lastWakeTimeHour = -1
                        wasConstrained = false
                    }
            )
    }

    // MARK: - Helper Methods

    /// Calculate sleep duration in minutes between bedtime and wakeTime
    private func calculateSleepDurationMinutes(bedtime: TimeOfDay, wakeTime: TimeOfDay) -> Int {
        let bedtimeMinutes = bedtime.hour * 60 + bedtime.minute
        let wakeMinutes = wakeTime.hour * 60 + wakeTime.minute
        
        if wakeMinutes >= bedtimeMinutes {
            // Same day (e.g., 10 AM bedtime, 6 PM wake - unusual but supported)
            return wakeMinutes - bedtimeMinutes
        } else {
            // Crosses midnight (normal case: 10 PM bedtime, 6 AM wake)
            return (24 * 60) - bedtimeMinutes + wakeMinutes
        }
    }
    
    /// Constrain sleep duration to maximum hours by adjusting the appropriate time
    /// When dragging bedtime, adjust wakeTime. When dragging wakeTime, adjust bedtime.
    private func constrainSleepDuration(bedtime: TimeOfDay, wakeTime: TimeOfDay, maxHours: Int) -> (bedtime: TimeOfDay, wakeTime: TimeOfDay) {
        let maxMinutes = maxHours * 60
        let currentDuration = calculateSleepDurationMinutes(bedtime: bedtime, wakeTime: wakeTime)
        
        // If duration is within limit, return as-is
        if currentDuration <= maxMinutes {
            return (bedtime: bedtime, wakeTime: wakeTime)
        }
        
        // Duration exceeds limit - need to constrain
        // Determine which time was being dragged by checking which one changed
        let wasDraggingBedtime = isDraggingBedtime && !isDraggingWakeTime
        let wasDraggingWakeTime = isDraggingWakeTime && !isDraggingBedtime
        
        let bedtimeMinutes = bedtime.hour * 60 + bedtime.minute
        let wakeMinutes = wakeTime.hour * 60 + wakeTime.minute
        
        if wasDraggingBedtime {
            // Adjust wakeTime to be exactly maxHours after bedtime (taking shorter path)
            var newWakeMinutes = bedtimeMinutes + maxMinutes
            if newWakeMinutes >= 24 * 60 {
                newWakeMinutes = newWakeMinutes - (24 * 60)
            }
            let newWakeHours = newWakeMinutes / 60
            let newWakeMins = newWakeMinutes % 60
            // Round to nearest 5 minutes
            let roundedMins = (newWakeMins / 5) * 5
            return (bedtime: bedtime, wakeTime: TimeOfDay(hour: newWakeHours, minute: roundedMins))
        } else if wasDraggingWakeTime {
            // Adjust bedtime to be exactly maxHours before wakeTime (taking shorter path)
            var newBedtimeMinutes = wakeMinutes - maxMinutes
            if newBedtimeMinutes < 0 {
                newBedtimeMinutes = newBedtimeMinutes + (24 * 60)
            }
            let newBedtimeHours = newBedtimeMinutes / 60
            let newBedtimeMins = newBedtimeMinutes % 60
            // Round to nearest 5 minutes
            let roundedMins = (newBedtimeMins / 5) * 5
            return (bedtime: TimeOfDay(hour: newBedtimeHours, minute: roundedMins), wakeTime: wakeTime)
        } else {
            // Neither is being dragged (shouldn't happen, but handle gracefully)
            // Default: adjust wakeTime
            var newWakeMinutes = bedtimeMinutes + maxMinutes
            if newWakeMinutes >= 24 * 60 {
                newWakeMinutes = newWakeMinutes - (24 * 60)
            }
            let newWakeHours = newWakeMinutes / 60
            let newWakeMins = newWakeMinutes % 60
            let roundedMins = (newWakeMins / 5) * 5
            return (bedtime: bedtime, wakeTime: TimeOfDay(hour: newWakeHours, minute: roundedMins))
        }
    }

    /// Calculate the shortest arc between two angles, ensuring the arc always represents
    /// the actual sleep duration (the shorter path between bedtime and wake-up time)
    private func calculateShortestArc(from startAngle: Angle, to endAngle: Angle) -> (start: Angle, end: Angle) {
        // Normalize angles to 0-360 range
        let startDegrees = startAngle.degrees.truncatingRemainder(dividingBy: 360)
        let endDegrees = endAngle.degrees.truncatingRemainder(dividingBy: 360)
        
        let normalizedStart = startDegrees < 0 ? startDegrees + 360 : startDegrees
        let normalizedEnd = endDegrees < 0 ? endDegrees + 360 : endDegrees
        
        // Calculate both possible arc lengths
        let clockwiseDistance: Double
        let counterClockwiseDistance: Double
        
        if normalizedEnd >= normalizedStart {
            // End is after start going clockwise
            clockwiseDistance = normalizedEnd - normalizedStart
            counterClockwiseDistance = 360 - clockwiseDistance
        } else {
            // End is before start, so we cross midnight going clockwise
            counterClockwiseDistance = normalizedStart - normalizedEnd
            clockwiseDistance = 360 - counterClockwiseDistance
        }
        
        // Always use the shorter path (which represents the actual sleep duration)
        // Return the angles in a way that the shape can draw the shorter arc
        // The shape will handle the direction based on which path is shorter
        return (start: Angle(degrees: normalizedStart), end: Angle(degrees: normalizedEnd))
    }

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

        // Normalize angles to 0-360 range
        let startDegrees = startAngle.degrees.truncatingRemainder(dividingBy: 360)
        let endDegrees = endAngle.degrees.truncatingRemainder(dividingBy: 360)
        
        let normalizedStart = startDegrees < 0 ? startDegrees + 360 : startDegrees
        let normalizedEnd = endDegrees < 0 ? endDegrees + 360 : endDegrees

        // Calculate both possible arc lengths to find the shorter path
        let clockwiseDistance: Double
        if normalizedEnd >= normalizedStart {
            clockwiseDistance = normalizedEnd - normalizedStart
        } else {
            clockwiseDistance = 360 - (normalizedStart - normalizedEnd)
        }
        let counterClockwiseDistance = 360 - clockwiseDistance
        
        // Use the shorter path (which represents the actual sleep duration)
        let useClockwise = clockwiseDistance <= counterClockwiseDistance

        // Adjust angles to start at top (0° = midnight)
        let adjustedStart = Angle(degrees: normalizedStart) - Angle(degrees: 90)
        let adjustedEnd = Angle(degrees: normalizedEnd) - Angle(degrees: 90)

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: adjustedStart,
            endAngle: adjustedEnd,
            clockwise: !useClockwise
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

        // Normalize angles to 0-360 range
        let startDegrees = startAngle.degrees.truncatingRemainder(dividingBy: 360)
        let endDegrees = endAngle.degrees.truncatingRemainder(dividingBy: 360)
        
        let normalizedStart = startDegrees < 0 ? startDegrees + 360 : startDegrees
        let normalizedEnd = endDegrees < 0 ? endDegrees + 360 : endDegrees

        // Calculate both possible arc lengths to find the shorter path
        let clockwiseDistance: Double
        if normalizedEnd >= normalizedStart {
            clockwiseDistance = normalizedEnd - normalizedStart
        } else {
            clockwiseDistance = 360 - (normalizedStart - normalizedEnd)
        }
        let counterClockwiseDistance = 360 - clockwiseDistance
        
        // Use the shorter path (which represents the actual sleep duration)
        let useClockwise = clockwiseDistance <= counterClockwiseDistance

        // Adjust angles to start at top
        let adjustedStart = Angle(degrees: normalizedStart) - Angle(degrees: 90)
        let adjustedEnd = Angle(degrees: normalizedEnd) - Angle(degrees: 90)

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: adjustedStart,
            endAngle: adjustedEnd,
            clockwise: !useClockwise
        )

        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: adjustedEnd,
            endAngle: adjustedStart,
            clockwise: useClockwise
        )

        path.closeSubpath()
        return path
    }
}
