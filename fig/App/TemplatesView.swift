//
//  TemplatesView.swift
//  fig
//
//  Created by Mayank Gandhi on 05/10/25.
//

import SwiftUI
import SwiftData

struct TemplatesView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TemplateCategory> { _ in true }) private var categories: [TemplateCategory]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(categories) { category in
                        CategorySection(category: category)
                    }
                }
                .padding()
            }
            .navigationTitle("Templates")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        .tint(.accentColor)
    }
}

struct CategorySection: View {
    let category: TemplateCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: category.colorHex) ?? .accentColor)

                Text(category.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal, 4)

            // Category Description
            Text(category.categoryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            // Templates Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(category.templates) { template in
                    TemplateCard(template: template, categoryColor: category.colorHex)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct TemplateCard: View {
    let template: AlarmItem
    let categoryColor: String

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            addTemplateToAlarms()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundStyle(Color(hex: categoryColor) ?? .accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Title
                Text(template.label)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Schedule info
                if let schedule = template.schedule {
                    Text(scheduleDescription(schedule))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Add button indicator
                HStack {
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: categoryColor) ?? .accentColor)
                }
            }
            .padding(12)
            .frame(height: 140)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func addTemplateToAlarms() {
        // Create a new AlarmItem from the template
        let newAlarm = AlarmItem(
            label: template.label,
            isEnabled: true,
            notes: template.notes,
            schedule: template.schedule,
            countdown: template.countdown,
            presentation: template.presentation
        )

        modelContext.insert(newAlarm)

        do {
            try modelContext.save()
        } catch {
            print("Error saving alarm: \(error)")
        }
    }

    private func scheduleDescription(_ schedule: TickerSchedule) -> String {
        switch schedule {
        case .oneTime(let date):
            return date.formatted(date: .abbreviated, time: .shortened)
        case .daily(let time):
            return "Daily at \(String(format: "%02d:%02d", time.hour, time.minute))"
//        case .weekly(let time, let weekdays):
//            let days = weekdays.sorted(by: { $0.rawValue < $1.rawValue })
//                .prefix(2)
//                .map { $0.shortName }
//                .joined(separator: ", ")
//            return "\(days)... at \(String(format: "%02d:%02d", time.hour, time.minute))"
        case .monthly(let time, let day):
            return "Day \(day) at \(String(format: "%02d:%02d", time.hour, time.minute))"
        case .yearly(let month, let day, _):
            return "\(month)/\(day)"
        }
    }
}

// Helper extension for hex color
extension Color {
    init?(hex: String) {
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

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension TickerSchedule.Weekday {
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: [TemplateCategory.self, AlarmItem.self])
}
