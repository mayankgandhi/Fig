//
//  NaturalLanguageTickerView.swift
//  fig
//
//  Natural language input for AI-powered ticker generation
//

import SwiftUI
import Combine

struct NaturalLanguageTickerView: View {
    @State private var viewModel: NaturalLanguageViewModel?

    #if DEBUG
    @State private var showDebugView = false
    #endif

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TickerService.self) private var tickerService


    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        initializeViewModel()
                    }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: NaturalLanguageViewModel) -> some View {
        ScrollView {
            VStack(spacing: TickerSpacing.xl) {
                // Header
                headerSection(viewModel: viewModel)

                // Input Section
                inputSection(viewModel: viewModel)

                // Conditional Content - OptionsPillsView (with time pill)
                // Use contentTransition for smooth streaming animations
                if viewModel.hasStartedTyping {
                    NaturalLanguageOptionsPillsView(
                        viewModel: viewModel
                    )
                    .contentTransition(.interpolate)
                }

                #if DEBUG
                // Debug View (if enabled) - Only in Debug builds
                if showDebugView {
                    AITickerGeneratorDebugView(aiGenerator: viewModel.aiGenerator)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                #endif

                // Generate Button
                generateButtonSection(viewModel: viewModel)
            }
            .padding(TickerSpacing.lg)
        }
        // Overlay presentation for all expandable fields
        .overlay(alignment: .top) {
            if let field = viewModel.optionsPillsViewModel.expandedField {
                NaturalLanguageExpandedFieldContent(field: field, viewModel: viewModel)
                    .zIndex(100)
            }
        }
        .background(backgroundView)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    TickerHaptics.selection()
                    // Cleanup session when dismissing
                    viewModel.cleanup()
                    dismiss()
                }
            }

            #if DEBUG
            ToolbarItem(placement: .primaryAction) {
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showDebugView.toggle()
                    }
                } label: {
                    Image(systemName: showDebugView ? "terminal.fill" : "terminal")
                        .font(.callout)
                        .foregroundStyle(showDebugView ? TickerColor.primary : TickerColor.textSecondary(for: colorScheme))
                }
            }
            #endif
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Error", isPresented: Binding(
            get: { viewModel.showingError },
            set: { viewModel.showingError = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            #if DEBUG
            // Enable debug mode for event logging (Debug builds only)
            viewModel.aiGenerator.isDebugMode = true
            #endif

            // Prepare AI session when view appears for optimal performance
            // This preloads the model before user starts typing
            await viewModel.prepareForAppearance()
        }
        .onReceive(viewModel.aiGenerator.$parsedConfiguration) { newConfig in
            // Update view models when parsed configuration changes
            // This runs on main thread automatically due to @MainActor on AITickerGenerator
            if newConfig != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.updateViewModelsFromParsedConfig()
                }
            }
        }
    }
    
    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(viewModel: NaturalLanguageViewModel) -> some View {
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
                    Image(systemName: viewModel.aiGenerator.isFoundationModelsAvailable ? "cpu.fill" : "brain.head.profile")
                        .font(.caption2)

                    Text(viewModel.aiGenerator.isFoundationModelsAvailable ? "Apple Intelligence" : "Smart Parsing")
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

    @ViewBuilder
    private func inputSection(viewModel: NaturalLanguageViewModel) -> some View {
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

                if viewModel.inputText.isEmpty {
                    Text("e.g., Wake up at 7am every weekday")
                        .Caption()
                        .foregroundStyle(TickerColor.textTertiary(for: colorScheme))
                        .padding(TickerSpacing.lg)
                }

                TextEditor(text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.inputText = $0 }
                ))
                    .Body()
                    .foregroundStyle(TickerColor.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(TickerSpacing.md)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Example Prompts Section
    
    
    
    // MARK: - Generate Button Section

    @ViewBuilder
    private func generateButtonSection(viewModel: NaturalLanguageViewModel) -> some View {
        Button {
            Task {
                await viewModel.generateAndSave()
                if !viewModel.showingError {
                    TickerHaptics.success()
                    // Cleanup session after successful save
                    viewModel.cleanup()
                    try? await Task.sleep(for: .milliseconds(500))
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: TickerSpacing.sm) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(TickerColor.absoluteWhite)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.callout.weight(.bold))
                }

                Text(viewModel.isSaving ? "Creating..." : "Create Ticker")
                    .Headline()
            }
            .foregroundStyle(TickerColor.absoluteWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TickerSpacing.lg)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            viewModel.isSaving ?
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

                    if viewModel.isSaving {
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
                                value: viewModel.isSaving
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
                color: TickerColor.primary.opacity(viewModel.isSaving ? 0.3 : 0.5),
                radius: viewModel.isSaving ? 6 : 12,
                x: 0,
                y: viewModel.isSaving ? 3 : 6
            )
            .scaleEffect(viewModel.isSaving ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isSaving)
        }
        .disabled(!viewModel.canGenerate)
        .opacity(viewModel.canGenerate ? 1.0 : 0.6)
    }
    
    // MARK: - Initialization

    private func initializeViewModel() {
        viewModel = NaturalLanguageViewModel(
            modelContext: modelContext,
            tickerService: tickerService
        )
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
    
}


// MARK: - Preview

#Preview {
    NaturalLanguageTickerView()
        .environment(TickerService())
        .modelContainer(for: Ticker.self, inMemory: true)
}
