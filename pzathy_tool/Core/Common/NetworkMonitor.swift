//
//  NetworkMonitor.swift
//  pzathy_tool
//
//  Observes connectivity with NWPathMonitor and publishes a simple `isConnected`
//  flag the UI can react to (e.g. a "No internet" popup before a conversion).
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {

    /// True when the device currently has a usable network path.
    @Published private(set) var isConnected: Bool = true
    /// True when the connection is over an expensive interface (cellular / hotspot).
    @Published private(set) var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let expensive = path.isExpensive
            Task { @MainActor [weak self] in
                self?.isConnected = connected
                self?.isExpensive = expensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
