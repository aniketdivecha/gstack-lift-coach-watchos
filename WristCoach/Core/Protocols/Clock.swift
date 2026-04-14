import CoreFoundation

protocol Clock {
    func now() -> CFAbsoluteTime
}

final class MonotonicClock: Clock {
    func now() -> CFAbsoluteTime {
        CFAbsoluteTimeGetCurrent()
    }
}
