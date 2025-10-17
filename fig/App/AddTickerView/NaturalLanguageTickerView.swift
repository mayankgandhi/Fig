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

                    // Example Prompts
                    examplePromptsSection

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
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(TickerColor.primary)
            }
            
            VStack(spacing: TickerSpacing.sm) {
                Text("Describe Your Ticker")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                
                Text("Tell me what kind of ticker you want, and I'll set it up for you")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TickerSpacing.md)
            }
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: TickerSpacing.md) {
            VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                Text("What do you want to be reminded about?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                
                Text("Be specific about the time, activity, and how often")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
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
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .padding(TickerSpacing.lg)
                }
                
                TextEditor(text: $inputText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(TickerSpacing.md)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Example Prompts Section
    
    private var examplePromptsSection: some View {
        VStack(spacing: TickerSpacing.md) {
            HStack {
                Text("Try these examples:")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                        .font(.system(size: 16, weight: .bold))
                }

                Text(aiGenerator.isGenerating ? "Generating..." : "Generate Ticker")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
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
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 10, weight: .semibold))
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
