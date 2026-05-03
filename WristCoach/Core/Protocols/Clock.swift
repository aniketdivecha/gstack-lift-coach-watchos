import Foundation

protocol Clock {
    func now() -> TimeInterval
}

final class MonotonicClock: Clock {
    func now() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}
