//
//  AlarmKitPermissionSheet.swift
//  Ticker
//
//  Created by Claude Code
//

import SwiftUI
import TickerCore
import Factory

struct AlarmKitPermissionSheet: View {
    // MARK: - Properties

    @Bindable var viewModel: AlarmKitPermissionViewModel
    let onDismiss: () -> Void
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            iconView
                .padding(.top, TickerSpacing.lg)
                .padding(.bottom, TickerSpacing.md)

            // Text Content
            VStack(spacing: TickerSpacing.sm) {
                titleView
                descriptionView
            }
            .padding(.bottom, TickerSpacing.md)

            Spacer(minLength: TickerSpacing.md)

            // Action Button
            actionButton
        }
        .padding(.horizontal, TickerSpacing.lg)
        .padding(.bottom, TickerSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .opacity(isVisible ? 1.0 : 0)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
            AnalyticsEvents.permissionPromptShown(context: "settings").track()
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
                .frame(width: 64, height: 64)

            Image(systemName: viewModel.authorizationStatus == .denied ? "lock.fill" : "alarm.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(TickerColor.absoluteWhite)
                .symbolEffect(.bounce, value: viewModel.authorizationStatus)
        }
        .glassEffect(.regular.tint(TickerColor.primary))
    }

    private var titleView: some View {
        Text(viewModel.title)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(TickerColor.textPrimary(for: .dark))
            .multilineTextAlignment(.center)
    }

    private var descriptionView: some View {
        Text(viewModel.description)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(TickerColor.textSecondary(for: .dark))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
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
    @Previewable @State var viewModel = AlarmKitPermissionViewModel()

    AlarmKitPermissionSheet(
        viewModel: viewModel,
        onDismiss: {}
    )
    .presentationDetents([.medium])
}
