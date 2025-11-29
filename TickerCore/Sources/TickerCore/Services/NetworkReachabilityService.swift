//
//  NetworkReachabilityService.swift
//  TickerCore
//
//  Service for monitoring network connectivity status
//  Uses NWPathMonitor to track reachability changes
//

import Foundation
import Network

/// Service for monitoring network reachability
/// Uses NWPathMonitor to track connectivity changes in real-time
public final class NetworkReachabilityService: @unchecked Sendable {

    // MARK: - Properties

    /// Singleton instance
    public static let shared = NetworkReachabilityService()

    /// Current network status
    private var currentStatus: NWPath.Status = .requiresConnection

    /// Path monitor
    private let monitor: NWPathMonitor

    /// Monitoring queue
    private let queue = DispatchQueue(label: "com.fig.networkMonitor")

    // MARK: - Computed Properties

    /// Whether network is currently reachable
    public var isReachable: Bool {
        currentStatus == .satisfied
    }

    /// Whether network is currently unreachable
    public var isUnreachable: Bool {
        !isReachable
    }

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    // MARK: - Methods

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentStatus = path.status
        }
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }

    deinit {
        stopMonitoring()
    }
}
