//
//  FAQView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI

struct FAQView: View {
    @State private var showFAQ = false

    var body: some View {
        NativeMenuListItem(
            icon: "questionmark.circle",
            title: "FAQ",
            subtitle: "Frequently asked questions",
            iconColor: .purple
        ) {
            showFAQ = true
        }
        .sheet(isPresented: $showFAQ) {
            FAQDetailView()
        }
    }
}

// MARK: - FAQ Item
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - FAQ Detail View
struct FAQDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "How do I create a new alarm?",
            answer: "Tap the '+' button in the Alarms tab to create a new alarm. You can choose quick presets or configure a custom alarm with countdowns, schedules, and secondary buttons."
        ),
        FAQItem(
            question: "What is a Pre-Alert (Countdown)?",
            answer: "A pre-alert countdown starts before your alarm goes off, giving you advance notice. For example, setting a 15-minute countdown means you'll get an alert 15 minutes before the main alarm."
        ),
        FAQItem(
            question: "What are scheduled alarms?",
            answer: "Scheduled alarms trigger at specific times (e.g., 8:00 AM). You can set them to repeat on certain days of the week or trigger just once."
        ),
        FAQItem(
            question: "What is the secondary button option?",
            answer: "The secondary button appears when your alarm triggers. You can choose 'Countdown' to add a repeat timer, 'Open App' to launch fig directly, or 'None' to show only the Stop button."
        ),
        FAQItem(
            question: "How do I delete an alarm?",
            answer: "In the Alarms tab, swipe left on any alarm and tap Delete. You can also view all alarms in Settings > Upcoming Alarms."
        ),
        FAQItem(
            question: "Why isn't my alarm triggering?",
            answer: "Make sure notifications are enabled for fig in your device Settings. Also check that your alarm is properly configured with either a countdown or schedule."
        ),
        FAQItem(
            question: "Can I have multiple alarms?",
            answer: "Yes! You can create as many alarms as you need. Each alarm can have its own label, schedule, and configuration."
        ),
        FAQItem(
            question: "How do I clear all my alarms?",
            answer: "Go to Settings > Data > Delete All Data. This will remove all scheduled alarms. This action cannot be undone."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(faqs) { faq in
                        FAQItemView(item: faq)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .navigationTitle("FAQ")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FAQ Item View
struct FAQItemView: View {
    let item: FAQItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.question)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

#Preview {
    FAQView()
}

#Preview("FAQ Detail") {
    FAQDetailView()
}
