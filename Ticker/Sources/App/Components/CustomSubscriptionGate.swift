//
//  CustomSubscriptionGate.swift
//  Ticker
//
//  Custom subscription gate that shows a bottom sheet for premium features
//

import SwiftUI
import Gate
import TickerCore

struct CustomSubscriptionGate<Content: View>: View {
    // MARK: - Properties
    
    let feature: PremiumFeature
    @ViewBuilder let content: () -> Content
    
    @State private var showPaywallSheet = false
    @State private var hasAccess = false
    @State private var hasCheckedAccess = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if hasAccess {
                content()
            } else {
                // Show gate sheet content instead of the actual content
                PremiumFeatureGateSheet(
                    feature: feature,
                    onDismiss: {},
                    onGoPro: {
                        showPaywallSheet = true
                    }
                )
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showPaywallSheet) {
            GatePaywallView()
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if !hasCheckedAccess {
                checkAccess()
            }
        }
    }
    
    // MARK: - Methods
    
    private func checkAccess() {
        hasCheckedAccess = true
        Task {
            // Check if user has access to the feature
            // Use isPremium as a general check, or check specific feature access if available
            let access = SubscriptionService.shared.isSubscribed
            
            await MainActor.run {
                hasAccess = access
            }
        }
    }
}

