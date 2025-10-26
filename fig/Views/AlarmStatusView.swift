//
//  AlarmStatusView.swift
//  fig
//
//  UI component displaying alarm health status and manual regeneration control
//  Shows last sync time, alarm count, and health indicators
//

import SwiftUI
import SwiftData

struct AlarmStatusView: View {
    let ticker: Ticker
    let regenerationService: AlarmRegenerationService
    @Environment(\.modelContext) private var modelContext

    @State private var isRegenerating = false
    @State private var health: AlarmHealth

    init(ticker: Ticker, regenerationService: AlarmRegenerationService = AlarmRegenerationService()) {
        self.ticker = ticker
        self.regenerationService = regenerationService
        _health = State(initialValue: ticker.alarmHealthStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: health.status.icon)
                    .foregroundStyle(colorForStatus(health.status))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Alarm Status")
                        .font(.headline)

                    Text(health.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Manual refresh button
                Button {
                    manualRefresh()
                } label: {
                    if isRegenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                    }
                }
                .disabled(isRegenerating)
                .buttonStyle(.borderless)
            }

            // Detailed status
            HStack(spacing: 16) {
                // Last updated
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Updated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(health.lastUpdatedDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Divider()
                    .frame(height: 30)

                // Alarm count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scheduled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(health.activeAlarmCount) alarm\(health.activeAlarmCount == 1 ? "" : "s")")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()
            }

            // Warning/Critical banner
            if health.status == .warning || health.status == .critical {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)

                    Text(health.status == .critical ? "Action required" : "Attention needed")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForStatus(health.status).opacity(0.15))
                )
                .foregroundStyle(colorForStatus(health.status))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .task {
            // Refresh health status periodically
            await updateHealth()
        }
    }

    // MARK: - Actions

    private func manualRefresh() {
        isRegenerating = true

        Task {
            do {
                // Force regeneration
                try await regenerationService.regenerateAlarmsIfNeeded(
                    ticker: ticker,
                    context: modelContext,
                    force: true
                )

                // Update health status
                await updateHealth()

                print("✅ Manual refresh completed")
            } catch {
                print("❌ Manual refresh failed: \(error)")
            }

            isRegenerating = false
        }
    }

    private func updateHealth() async {
        health = await regenerationService.calculateAlarmHealth(ticker: ticker)
    }

    // MARK: - Helpers

    private func colorForStatus(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Compact Status Badge

/// Compact badge showing just the health icon for inline use
struct AlarmStatusBadge: View {
    let ticker: Ticker

    var body: some View {
        let health = ticker.alarmHealthStatus

        HStack(spacing: 4) {
            Image(systemName: health.status.icon)
                .font(.caption2)
                .foregroundStyle(colorForStatus(health.status))

            if health.status != .healthy {
                Text(health.activeAlarmCount.description)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(colorForStatus(health.status).opacity(0.15))
        )
    }

    private func colorForStatus(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Preview

#Preview("Healthy Status") {
    @Previewable @State var ticker = Ticker(
        id: UUID(),
        label: "Daily Standup",
        schedule: .daily(time: .init(hour: 9, minute: 0))
    )

    // Simulate healthy status
    ticker.lastRegenerationDate = Date().addingTimeInterval(-300) // 5 minutes ago
    ticker.lastRegenerationSuccess = true
    ticker.generatedAlarmKitIDs = [UUID(), UUID(), UUID()]

    return AlarmStatusView(ticker: ticker)
        .padding()
}

#Preview("Warning Status") {
    @Previewable @State var ticker = Ticker(
        id: UUID(),
        label: "Daily Standup",
        schedule: .daily(time: .init(hour: 9, minute: 0))
    )

    // Simulate warning status (stale)
    ticker.lastRegenerationDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
    ticker.lastRegenerationSuccess = true
    ticker.generatedAlarmKitIDs = [UUID(), UUID()]

    return AlarmStatusView(ticker: ticker)
        .padding()
}

#Preview("Critical Status") {
    @Previewable @State var ticker = Ticker(
        id: UUID(),
        label: "Daily Standup",
        schedule: .daily(time: .init(hour: 9, minute: 0))
    )

    // Simulate critical status (failed)
    ticker.lastRegenerationDate = Date().addingTimeInterval(-600) // 10 minutes ago
    ticker.lastRegenerationSuccess = false
    ticker.generatedAlarmKitIDs = []

    return AlarmStatusView(ticker: ticker)
        .padding()
}

#Preview("Status Badge") {
    @Previewable @State var ticker = Ticker(
        id: UUID(),
        label: "Daily Standup",
        schedule: .daily(time: .init(hour: 9, minute: 0))
    )

    ticker.lastRegenerationDate = Date()
    ticker.lastRegenerationSuccess = true
    ticker.generatedAlarmKitIDs = [UUID(), UUID(), UUID()]

    return HStack {
        AlarmStatusBadge(ticker: ticker)
    }
    .padding()
}
