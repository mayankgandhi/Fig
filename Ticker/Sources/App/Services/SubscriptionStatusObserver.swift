//
//  SubscriptionStatusObserver.swift
//  Ticker
//
//  Bridges the Gate subscription service with WidgetKit by caching the
//  entitlement state inside the shared App Group and forcing widget reloads
//  whenever the subscription status changes.
//

import Foundation
import Combine
import Gate
import WidgetKit
import TickerCore

final class SubscriptionStatusObserver {
    static let shared = SubscriptionStatusObserver()

    private var cancellables = Set<AnyCancellable>()
    private var hasStarted = false

    private init() {}

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        // Persist the initial value immediately so widgets have data on launch.
        SubscriptionAccessStore.setIsSubscribed(SubscriptionService.shared.isSubscribed)

        SubscriptionService.shared.$isSubscribed
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { isSubscribed in
                SubscriptionAccessStore.setIsSubscribed(isSubscribed)
                WidgetCenter.shared.reloadAllTimelines()
            }
            .store(in: &cancellables)
    }
}

