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
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<TemplateCategory> { _ in true }) private var categories: [TemplateCategory]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    Section {
                        ForEach(category.templates) { template in
                            TemplateRow(
                                template: template,
                                categoryName: category.name,
                                categoryIcon: category.icon,
                                categoryColor: category.colorHex
                            )
                        }
                    } header: {
                        CategoryHeader(category: category)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    TickerColors.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    // Subtle overlay for glass effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
.opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Templates")
        }
    }
}

struct CategoryHeader: View {
    let category: TemplateCategory
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TickerSpacing.xs) {
            Image(systemName: category.icon)
                .foregroundStyle(Color(hex: category.colorHex) ?? TickerColors.primary)

            Text(category.name)
                .textCase(.uppercase)
                .cabinetCaption2()
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
        }
    }
}

struct TemplateRow: View {
    let template: Ticker
    let categoryName: String
    let categoryIcon: String
    let categoryColor: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            TickerHaptics.standardAction()
            addTemplateToAlarms()
        } label: {
            HStack(spacing: TickerSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: categoryColor)?.opacity(0.15) ?? TickerColors.primary.opacity(0.15))
                        .frame(width: TickerSpacing.tapTargetPreferred, height: TickerSpacing.tapTargetPreferred)

                    Image(systemName: template.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color(hex: categoryColor) ?? TickerColors.primary)
                }

                // Content
                VStack(alignment: .leading, spacing: TickerSpacing.xxs) {
                    Text(template.label)
                        .cabinetBody()
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))

                    if let schedule = template.schedule {
                        Text(scheduleDescription(schedule))
                            .cabinetFootnote()
                            .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                // Disclosure indicator
                Image(systemName: "chevron.right")
                    .cabinetFootnote()
                    .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addTemplateToAlarms() {
        // Create TickerData from category information
        let tickerData = TickerData(
            name: categoryName,
            icon: categoryIcon,
            colorHex: categoryColor
        )

        // Create a new Ticker from the template
        let newAlarm = Ticker(
            label: template.label,
            isEnabled: true,
            notes: template.notes,
            schedule: template.schedule,
            countdown: template.countdown,
            presentation: template.presentation,
            tickerData: tickerData
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
        .modelContainer(for: [TemplateCategory.self, Ticker.self])
}
