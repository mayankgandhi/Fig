//
//  NaturalLanguageTickerView.swift
//  fig
//
//  Natural language input for AI-powered ticker generation
//

import SwiftUI

struct NaturalLanguageTickerView: View {
    @StateObject private var aiGenerator = AITickerGenerator()
    @State private var inputText = ""
    @State private var hasStartedTyping = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TickerService.self) private var tickerService
    
    private let examplePrompts = [
        "Wake up at 7am every weekday",
        "Remind me to take medication at 9am and 9pm daily",
        "Morning yoga every Monday, Wednesday, Friday at 7am",
        "Team meeting next Tuesday at 2:30pm",
        "Lunch break at 12pm with 5 minute countdown",
        "Bedtime reminder at 10pm daily",
        "Gym workout every Tuesday and Thursday at 6pm",
        "Coffee break at 3pm with 10 minute countdown"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Header
                    headerSection

                    // Input Section
                    inputSection

                    // Conditional Content
                    if hasStartedTyping {
                        parsedDataPreviewSection
                    } else {
                        examplePromptsSection
                    }

                    // Generate Button
                    generateButtonSection
                }
                .padding(TickerSpacing.lg)
            }
            .background(backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        TickerHaptics.selection()
                        dismiss()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: TickerSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TickerColor.primary.opacity(0.2),
                                TickerColor.primary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .foregroundStyle(TickerColor.primary)
            }

            VStack(spacing: TickerSpacing.sm) {
                Text("Describe Your Ticker")
                    .TickerTitle()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)

                // AI Status Indicator
                HStack(spacing: TickerSpacing.xs) {
                    Image(systemName: aiGenerator.isFoundationModelsAvailable ? "cpu.fill" : "brain.head.profile")
                        .font(.caption2)

                    Text(aiGenerator.isFoundationModelsAvailable ? "Apple Intelligence" : "Smart Parsing")
                        .Caption2()
                }
                .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                .padding(.horizontal, TickerSpacing.md)
                .padding(.vertical, TickerSpacing.xs)
                .background(
                    Capsule()
                        .fill(TickerColor.surface(for: colorScheme).opacity(0.5))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            TickerColor.primary.opacity(0.2),
                            lineWidth: 0.5
                        )
                )
            }
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: TickerSpacing.md) {
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("What do you want to be reminded about?")
                    .Headline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text("Be specific about the time, activity, and how often")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Text Input
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: TickerRadius.large)
                    .fill(TickerColor.surface(for: colorScheme).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        TickerColor.primary.opacity(0.3),
                                        TickerColor.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(minHeight: 120)
                
                if inputText.isEmpty {
                    Text("e.g., Wake up at 7am every weekday")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .padding(TickerSpacing.lg)
                }
                
                TextEditor(text: $inputText)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(TickerSpacing.md)
                    .onChange(of: inputText) { _, newValue in
                        if !hasStartedTyping && !newValue.isEmpty {
                            hasStartedTyping = true
                        }
                        
                        // Trigger background parsing
                        aiGenerator.parseInBackground(from: newValue)
                    }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Example Prompts Section
    
    private var examplePromptsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            HStack {
                Text("Try these examples:")
                    .Subheadline()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: TickerSpacing.sm) {
                ForEach(examplePrompts.prefix(6), id: \.self) { prompt in
                    ExamplePromptCard(
                        prompt: prompt,
                        onTap: {
                            TickerHaptics.selection()
                            inputText = prompt
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Generate Button Section

    private var generateButtonSection: some View {
        Button {
            Task {
                await generateTicker()
            }
        } label: {
            HStack(spacing: TickerSpacing.sm) {
                if aiGenerator.isGenerating {
                    ProgressView()
                        .tint(TickerColor.absoluteWhite)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.callout.weight(.bold))
                }

                Text(aiGenerator.isGenerating ? "Creating..." : "Create Ticker")
                    .Headline()
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TickerSpacing.lg)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            aiGenerator.isGenerating ?
                            LinearGradient(
                                colors: [
                                    TickerColor.primary.opacity(0.8),
                                    TickerColor.primary.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    TickerColor.primary,
                                    TickerColor.primary.opacity(0.95),
                                    TickerColor.primary.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if aiGenerator.isGenerating {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: -50)
                            .animation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                                value: aiGenerator.isGenerating
                            )
                    }
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        TickerColor.absoluteWhite.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: TickerColor.primary.opacity(aiGenerator.isGenerating ? 0.3 : 0.5),
                radius: aiGenerator.isGenerating ? 6 : 12,
                x: 0,
                y: aiGenerator.isGenerating ? 3 : 6
            )
            .scaleEffect(aiGenerator.isGenerating ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: aiGenerator.isGenerating)
        }
        .disabled(aiGenerator.isGenerating || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(aiGenerator.isGenerating || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Parsed Data Preview Section
    
    private var parsedDataPreviewSection: some View {
        VStack(spacing: TickerSpacing.md) {
            HStack {
                Text("PARSED OPTIONS")
                    .Caption2()
                    .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Spacer()
                
                // Subtle indicator for parsed data
                if aiGenerator.parsedConfiguration != nil {
                    Circle()
                        .fill(TickerColor.primary)
                        .frame(width: 6, height: 6)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            
            if let configuration = aiGenerator.parsedConfiguration {
                // Show parsed data as pills
                FlowLayout(spacing: TickerSpacing.sm) {
                    // Activity/Label pill
                    TickerPill(
                        icon: "tag",
                        title: configuration.label.isEmpty ? "Activity" : configuration.label,
                        hasValue: !configuration.label.isEmpty,
                        size: .standard
                    )
                    
                    // Time pill
                    let timeString = formatTime(configuration.time)
                    TickerPill(
                        icon: "clock",
                        title: timeString,
                        hasValue: true,
                        size: .standard
                    )
                    
                    // Repeat pattern pill
                    let repeatString = formatRepeatPattern(configuration.repeatOption)
                    TickerPill(
                        icon: "repeat",
                        title: repeatString,
                        hasValue: true,
                        size: .standard
                    )
                    
                    // Countdown pill (if present)
                    if let countdown = configuration.countdown {
                        let countdownString = formatCountdown(countdown)
                        TickerPill(
                            icon: "timer",
                            title: countdownString,
                            hasValue: true,
                            size: .standard
                        )
                    }
                    
                    // Icon pill with selected color
                    TickerPill(
                        icon: configuration.icon,
                        title: "Icon",
                        hasValue: true,
                        size: .standard,
                        iconTintColor: Color(hex: configuration.colorHex) ?? TickerColor.primary
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
            } else {
                // Loading state with shimmer pills
                FlowLayout(spacing: TickerSpacing.sm) {
                    ShimmerPill(width: 100, height: 40)
                    ShimmerPill(width: 80, height: 40)
                    ShimmerPill(width: 120, height: 40)
                    ShimmerPill(width: 90, height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: aiGenerator.parsedConfiguration)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TickerConfiguration.TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let components = DateComponents(hour: time.hour, minute: time.minute)
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(time.hour):\(String(format: "%02d", time.minute))"
    }
    
    private func formatRepeatPattern(_ repeatOption: AITickerGenerator.RepeatOption) -> String {
        switch repeatOption {
        case .oneTime:
            return "One time"
        case .daily:
            return "Daily"
        case .weekdays(let weekdays):
            if weekdays.count == 5 && weekdays.contains(.monday) && weekdays.contains(.friday) {
                return "Weekdays"
            }
            let dayNames = weekdays.map { $0.shortName }.joined(separator: ", ")
            return dayNames
        case .hourly(let interval, let startTime, let endTime):
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            var text = "Every \(interval) hour\(interval == 1 ? "" : "s")"
            text += " from \(timeFormatter.string(from: startTime))"
            if let end = endTime {
                text += " to \(timeFormatter.string(from: end))"
            }
            return text
        case .every(let interval, let unit, let startTime, let endTime):
            let unitName = interval == 1 ? unit.singularName : unit.displayName.lowercased()
            let timeFormatter = DateFormatter()
            switch unit {
            case .minutes, .hours:
                timeFormatter.dateFormat = "h:mm a"
            case .days, .weeks:
                timeFormatter.dateStyle = .short
                timeFormatter.timeStyle = .short
            }
            var text = "Every \(interval) \(unitName)"
            text += " from \(timeFormatter.string(from: startTime))"
            if let end = endTime {
                text += " to \(timeFormatter.string(from: end))"
            }
            return text
        case .biweekly(let weekdays):
            let dayNames = weekdays.map { $0.shortName }.joined(separator: ", ")
            return "Biweekly (\(dayNames))"
        case .monthly(let monthlyDay):
            switch monthlyDay {
            case .fixed(let day):
                return "Monthly (day \(day))"
            case .firstWeekday(let weekday):
                return "First \(weekday.displayName)"
            case .lastWeekday(let weekday):
                return "Last \(weekday.displayName)"
            case .firstOfMonth:
                return "First of month"
            case .lastOfMonth:
                return "Last of month"
            }
        case .yearly(let month, let day):
            let monthName = Calendar.current.monthSymbols[month - 1]
            return "Yearly (\(monthName) \(day))"
        }
    }
    
    private func formatCountdown(_ countdown: TickerConfiguration.CountdownConfiguration) -> String {
        var parts: [String] = []
        
        if countdown.hours > 0 {
            parts.append("\(countdown.hours) hour\(countdown.hours == 1 ? "" : "s")")
        }
        if countdown.minutes > 0 {
            parts.append("\(countdown.minutes) minute\(countdown.minutes == 1 ? "" : "s")")
        }
        if countdown.seconds > 0 {
            parts.append("\(countdown.seconds) second\(countdown.seconds == 1 ? "" : "s")")
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            TickerColor.liquidGlassGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Actions

    private func generateTicker() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        do {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: inputText)
            let parser = TickerConfigurationParser()
            let ticker = parser.parseToTicker(from: configuration)

            // Save the ticker immediately
            modelContext.insert(ticker)
            try modelContext.save()

            // Schedule the alarm
            try await tickerService.scheduleAlarm(from: ticker, context: modelContext)

            TickerHaptics.success()
            showingSuccess = true

            // Dismiss the view after a brief success indication
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Example Prompt Card

struct ExamplePromptCard: View {
    let prompt: String
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: TickerSpacing.xs) {
                Text(prompt)
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TickerColor.primary)
                }
            }
            .padding(TickerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .fill(TickerColor.surface(for: colorScheme).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TickerRadius.medium)
                    .strokeBorder(
                        TickerColor.primary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview

#Preview {
    NaturalLanguageTickerView()
        .environment(TickerService())
        .modelContainer(for: Ticker.self, inMemory: true)
}
