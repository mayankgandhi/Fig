//
//  AlarmKitPermissionSheet.swift
//  Ticker
//
//  Created by Claude Code
//

import SwiftUI
import TickerCore

struct AlarmKitPermissionSheet: View {
    // MARK: - Properties

    @Bindable var viewModel: AlarmKitPermissionViewModel
    let onDismiss: () -> Void
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Icon with more prominence
            iconView
                .padding(.top, TickerSpacing.xxl)
                .padding(.bottom, TickerSpacing.xl)

            // Text Content
            VStack(spacing: TickerSpacing.md) {
                titleView
                descriptionView
            }
            .padding(.bottom, TickerSpacing.lg)

            // Features list (only shown for notDetermined)
            if !viewModel.features.isEmpty {
                featuresView
                    .padding(.bottom, TickerSpacing.xl)
            }

            Spacer(minLength: TickerSpacing.xl)

            // Action Button
            actionButton
        }
        .padding(.horizontal, TickerSpacing.xl)
        .padding(.bottom, TickerSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .opacity(isVisible ? 1.0 : 0)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }

    // MARK: - Subviews

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            TickerColor.primary.opacity(0.2),
                            TickerColor.primary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)

            Image(systemName: viewModel.authorizationStatus == .denied ? "lock.fill" : "alarm.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(TickerColor.absoluteWhite)
                .symbolEffect(.bounce, value: viewModel.authorizationStatus)
        }
        .glassEffect(.regular.tint(TickerColor.primary))
    }

    private var titleView: some View {
        Text(viewModel.title)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(TickerColor.textPrimary(for: .dark))
            .multilineTextAlignment(.center)
    }

    private var descriptionView: some View {
        Text(viewModel.description)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(TickerColor.textSecondary(for: .dark))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: TickerSpacing.md) {
            ForEach(viewModel.features, id: \.self) { feature in
                HStack(spacing: TickerSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(TickerColor.primary)
                        .symbolEffect(.pulse, options: .repeating)

                    Text(feature)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(TickerColor.textPrimary(for: .dark))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TickerSpacing.md)
                .padding(.vertical, TickerSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(.horizontal, TickerSpacing.sm)
    }

    @ViewBuilder
    private var actionButton: some View {
        Button(action: handleButtonAction) {
            HStack(spacing: TickerSpacing.sm) {
                if viewModel.isRequestingPermission {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(viewModel.buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TickerColor.primary)
                .shadow(color: TickerColor.primary.opacity(0.3), radius: 12, y: 4)
        )
        .glassEffect(.regular.interactive())
        .disabled(viewModel.isRequestingPermission)
        .opacity(viewModel.isRequestingPermission ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRequestingPermission)
    }

    private var backgroundGradient: some View {
        TickerColor.liquidGlassGradient(for: .dark)
            .ignoresSafeArea()
    }

    // MARK: - Actions

    private func handleButtonAction() {
        TickerHaptics.standardAction()

        switch viewModel.authorizationStatus {
        case .notDetermined:
            Task {
                await viewModel.requestPermission()

                // Check if permission was granted and dismiss
                if viewModel.authorizationStatus == .authorized {
                    TickerHaptics.success()
                    // Small delay for success feedback
                    try? await Task.sleep(for: .milliseconds(300))
                    onDismiss()
                } else if viewModel.authorizationStatus == .denied {
                    TickerHaptics.error()
                }
            }

        case .denied:
            viewModel.openSettings()

        case .authorized:
            TickerHaptics.success()
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = AlarmKitPermissionViewModel(
        tickerService: TickerService()
    )

    return AlarmKitPermissionSheet(
        viewModel: viewModel,
        onDismiss: {}
    )
    .presentationDetents([.medium])
}
