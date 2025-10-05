//
//  ClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct ClockView: View {
    
    struct TimeBlock: Identifiable {
        let id: UUID
        let city: String
        let hour: Int
        let minute: Int
        let color: Color
        
        var angle: Double {
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / 720.0) * 360.0
        }
        
        var timeString: String {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }
    
    struct HourMark: Identifiable {
        var id: Int
        var time: Int?
        var angle: Double
    }
    
    let events: [TimeBlock]
    
    var hourMarks: [HourMark] = [
        HourMark(id: 0, time: 12, angle: 0),
        HourMark(id: 1, time: nil, angle: 30),
        HourMark(id: 2, time: nil, angle: 60),
        HourMark(id: 3, time: 3, angle: 90),
        HourMark(id: 4, time: nil, angle: 120),
        HourMark(id: 5, time: nil, angle: 150),
        HourMark(id: 6, time: 6, angle: 180),
        HourMark(id: 7, time: nil, angle: 210),
        HourMark(id: 8, time: nil, angle: 240),
        HourMark(id: 9, time: 9, angle: 270),
        HourMark(id: 10, time: nil, angle: 300),
        HourMark(id: 11, time: nil, angle: 330),
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let markOffset = radius * 0.85
            let handLength = radius * 0.7
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                ForEach(hourMarks) { hourmark in
                    Rectangle()
                        .fill(hourmark.time != nil ? Color.black : Color.gray.opacity(0.5))
                        .frame(
                            width: hourmark.time != nil ? 2 : 1,
                            height: hourmark.time != nil ? radius * 0.08 : radius * 0.04
                        )
                        .offset(y: -markOffset)
                        .rotationEffect(Angle(degrees: hourmark.angle))
                    
                    if let time = hourmark.time {
                        Text("\(time)")
                            .font(.cabinetTitle2)
                            .fontWeight(.bold)
                            .offset(y: -radius * 0.7)
                            .rotationEffect(Angle(degrees: hourmark.angle))
                    }
                }
                
                ForEach(events) { event in
                    ZStack {
                        RoundedRectangle(cornerRadius: handLength * 0.08)
                            .fill(event.color)
                            .frame(width: handLength * 0.15, height: handLength)
                            .offset(y: -handLength / 2)
                        
                        HStack(spacing: 4) {
                            Text(event.city)
                                .font(.cabinetBody)
                                .fontWeight(.semibold)
                            Text(event.timeString)
                                .font(.cabinetCallout)
                                .fontWeight(.regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(event.color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .rotationEffect(Angle(degrees: event.angle))
                }
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: radius * 0.08, height: radius * 0.08)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.width,
                alignment: .center
            )
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
