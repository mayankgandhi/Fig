//
//  ClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI

struct ClockView: View {

    struct HourMark: Identifiable {
        var id: Int
        var time: Int?
        var angle: Double
    }

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

            ZStack {
                Circle()
                    .foregroundStyle(Color.gray.opacity(0.2))

                Circle()
                    .foregroundStyle(Color.red)
                    .frame(width: radius / 10, height: radius / 10)

                ForEach(hourMarks) { hourmark in
                    VStack(spacing: 4) {
                        if let time = hourmark.time {
                            Text("\(time)")
                                .font(.cabinetBody)
                                .fontWeight(.medium)
                        }

                        Rectangle()
                            .frame(width: radius / 40, height: radius / 10)
                            .foregroundStyle(Color.green)
                    }
                    .offset(y: -markOffset)
                    .rotationEffect(Angle(degrees: hourmark.angle))
                }
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
    ClockView()
}
