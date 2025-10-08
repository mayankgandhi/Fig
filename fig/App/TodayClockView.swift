//
//  TodayClockView.swift
//  fig
//
//  Created by Mayank Gandhi on 07/10/25.
//

import SwiftUI
import SwiftData
import WalnutDesignSystem

struct TodayClockView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<AlarmItem> { alarm in
        alarm.isEnabled == true
    }, sort: \AlarmItem.createdAt) private var alarms: [AlarmItem]

    @State private var showSettings: Bool = false

    private var events: [ClockView.TimeBlock] {
        alarms.compactMap { alarm -> ClockView.TimeBlock? in
            guard let schedule = alarm.schedule else { return nil }

            let (hour, minute) = extractTime(from: schedule)
            let color = extractColor(from: alarm)
            let label = alarm.displayName

            return ClockView.TimeBlock(
                id: alarm.id,
                city: label,
                hour: hour,
                minute: minute,
                color: color
            )
        }
    }

    var body: some View {
        NavigationStack {
            ClockView(events: events)
                .navigationTitle("Today")
                .toolbarTitleDisplayMode(.inlineLarge)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            
                .sheet(isPresented: $showSettings, content: {
                    SettingsView()
                        .presentationCornerRadius(Spacing.large)
                        .presentationDragIndicator(.visible)
                })
        }
    }

    // MARK: - Helper Functions

    private func extractTime(from schedule: TickerSchedule) -> (hour: Int, minute: Int) {
        switch schedule {
        case .oneTime(let date):
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (components.hour ?? 0, components.minute ?? 0)

        case .daily(let time):
            return (time.hour, time.minute)
        }
    }

    private func extractColor(from alarm: AlarmItem) -> Color {
        // Try to get color from ticker data
        if let colorHex = alarm.tickerData?.colorHex,
           let color = hexToColor(colorHex) {
            return color
        }

        // Try to get color from presentation
        if let tintHex = alarm.presentation.tintColorHex,
           let color = hexToColor(tintHex) {
            return color
        }

        // Default to accent color
        return .accentColor
    }

    private func hexToColor(_ hex: String) -> Color? {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    TodayClockView()
        .modelContainer(for: [AlarmItem.self, TemplateCategory.self])
}
