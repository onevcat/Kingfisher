//
//  NetworkMonitor.swift
//  Kingfisher
//
//  Created by Vladislav Komkov on 2025/09/22.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Network
import Foundation

/// A protocol for network connectivity monitoring that allows for dependency injection and testing.
internal protocol NetworkMonitoring: Sendable {
    /// Whether the network is currently connected.
    var isConnected: Bool { get }

    /// Observes network connectivity changes with an optional timeout.
    /// - Parameters:
    ///   - timeoutInterval: The timeout for waiting for network reconnection. If nil, no timeout is applied.
    ///   - callback: The callback to be called when network state changes or timeout occurs.
    /// - Returns: A cancellable observer that can be used to cancel the observation.
    func observeConnectivity(timeoutInterval: TimeInterval?, callback: @escaping @Sendable (Bool) -> Void) -> NetworkObserver
}

/// A protocol for network observers that can be cancelled.
internal protocol NetworkObserver: Sendable {
    /// Cancels the network observation.
    func cancel()
}

/// A shared singleton that manages network connectivity monitoring.
/// This prevents creating multiple NWPathMonitor instances when many NetworkRetryStrategy instances are used.
/// The monitor is created lazily only when first accessed.
internal final class NetworkMonitor: @unchecked Sendable, NetworkMonitoring {
    static let `default` = NetworkMonitor()

    /// Whether the network is currently connected.
    var isConnected: Bool {
        return monitor.currentPath.status == .satisfied
    }

    /// The network path monitor for observing connectivity changes.
    private let monitor = NWPathMonitor()

    /// The queue for monitoring network changes.
    private let monitorQueue = DispatchQueue(label: "com.onevcat.Kingfisher.NetworkMonitor", qos: .utility)

    /// Observers waiting for network reconnection.
    private var observers: [NetworkObserverImpl] = []
    private let observersQueue = DispatchQueue(label: "com.onevcat.Kingfisher.NetworkMonitor.Observers", attributes: .concurrent)

    /// Whether the monitor has been started.
    private var isStarted = false
    private let startQueue = DispatchQueue(label: "com.onevcat.Kingfisher.NetworkMonitor.Start")

    private init() {
        // Set up path monitoring
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }

    /// Starts monitoring if not already started.
    private func startMonitoring() {
        startQueue.sync {
            guard !isStarted else { return }
            monitor.start(queue: monitorQueue)
            isStarted = true
        }
    }

    /// Handles network path updates and notifies observers.
    private func handlePathUpdate(_ path: NWPath) {
        let connected = path.status == .satisfied
        guard connected else { return }

        // Notify all observers that network is available
        observersQueue.async(flags: .barrier) {
            let activeObservers = self.observers
            self.observers.removeAll()

            DispatchQueue.main.async {
                activeObservers.forEach { $0.notify(isConnected: true) }
            }
        }
    }

    /// Adds an observer for network reconnection.
    private func addObserver(_ observer: NetworkObserverImpl) {
        startMonitoring()

        observersQueue.async(flags: .barrier) {
            self.observers.append(observer)
        }
    }

    /// Removes an observer.
    internal func removeObserver(_ observer: NetworkObserverImpl) {
        observersQueue.async(flags: .barrier) {
            self.observers.removeAll { $0 === observer }
        }
    }

    // MARK: - NetworkMonitoring

    public func observeConnectivity(timeoutInterval: TimeInterval?, callback: @escaping @Sendable (Bool) -> Void) -> NetworkObserver {
        let observer = NetworkObserverImpl(
            timeoutInterval: timeoutInterval,
            callback: callback,
            monitor: self
        )
        addObserver(observer)
        return observer
    }
}

/// Internal implementation of network observer that manages timeout and callbacks.
internal final class NetworkObserverImpl: @unchecked Sendable, NetworkObserver {
    let timeoutInterval: TimeInterval?
    let callback: @Sendable (Bool) -> Void
    private weak var monitor: NetworkMonitor?
    private var timeoutWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.onevcat.Kingfisher.NetworkObserver", qos: .utility)

    init(timeoutInterval: TimeInterval?, callback: @escaping @Sendable (Bool) -> Void, monitor: NetworkMonitor) {
        self.timeoutInterval = timeoutInterval
        self.callback = callback
        self.monitor = monitor

        // Set up timeout if specified
        if let timeoutInterval = timeoutInterval {
            let workItem = DispatchWorkItem { [weak self] in
                self?.notify(isConnected: false)
            }
            timeoutWorkItem = workItem
            queue.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
        }
    }

    func notify(isConnected: Bool) {
        queue.async { [weak self] in
            guard let self else { return }

            // Cancel timeout if we're notifying
            timeoutWorkItem?.cancel()
            timeoutWorkItem = nil

            // Remove from monitor
            monitor?.removeObserver(self)

            // Call the callback
            DispatchQueue.main.async {
                self.callback(isConnected)
            }
        }
    }

    func cancel() {
        queue.async { [weak self] in
            guard let self else { return }

            // Cancel timeout
            timeoutWorkItem?.cancel()
            timeoutWorkItem = nil

            // Remove from monitor
            monitor?.removeObserver(self)
        }
    }
}
