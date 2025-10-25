//
//  AlarmDetailView.swift
//  fig
//
//  Detailed view showing comprehensive ticker information in a compact bottom sheet
//

import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    let alarm: Ticker
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(TickerService.self) private var tickerService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Header with icon and label
                    AlarmDetailHeader(alarm: alarm, tickerService: tickerService)

                    // Time display
                    AlarmDetailTimeSection(alarm: alarm)

                    // Options display with enhanced styling
                    AlarmDetailOptionsSection(alarm: alarm)
                        .padding(.top, TickerSpacing.sm)
                }
                .padding(TickerSpacing.md)
                .padding(.bottom, TickerSpacing.xl)
            }
            .background(
                ZStack {
                    TickerColor.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("Ticker Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        TickerHaptics.selection()
                        onEdit()
                        dismiss()
                    } label: {
                        Image(systemName: "pencil")
                            .Callout()
                            .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    }

                    Button(role: .destructive) {
                        TickerHaptics.selection()
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .Callout()
                            .foregroundStyle(.red)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

}

// MARK: - Preview

#Preview {
    @Previewable @State var tickerService = TickerService()

    AlarmDetailView(
        alarm: Ticker(
            label: "Morning Workout",
            isEnabled: true,
            schedule:
                    .daily(
                        time: TickerSchedule.TimeOfDay(hour: 6, minute: 30)
                    ),
            countdown: TickerCountdown(
                preAlert: TickerCountdown.CountdownDuration(hours: 0, minutes: 5, seconds: 0),
                postAlert: nil
            ),
            tickerData: TickerData(
                name: "Fitness & Health",
                icon: "figure.run",
                colorHex: "#FF6B35"
            )
        ),
        onEdit: {
},
        onDelete: {}
    )
    .environment(tickerService)
}
