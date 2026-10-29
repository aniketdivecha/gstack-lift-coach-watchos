import Foundation

/// The seam between sync logic and WatchConnectivity. The app plugs in a
/// WCSession adapter; tests and previews plug in the recorder below.
public protocol WatchMessageSender: Sendable {
    func send(_ message: WatchMessage) async throws
}

/// Records what the coordinator tried to send. `shouldFail` exists so tests can
/// prove that a transport error is not swallowed.
public actor RecordingWatchTransport: WatchMessageSender {
    public enum Failure: Error, Equatable, Sendable {
        case sendFailed
    }

    private let shouldFail: Bool
    public private(set) var sent: [WatchMessage] = []

    public init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    public func send(_ message: WatchMessage) throws {
        if shouldFail {
            throw Failure.sendFailed
        }
        sent.append(message)
    }
}
