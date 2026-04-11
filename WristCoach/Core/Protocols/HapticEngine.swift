import WatchKit

protocol HapticEngine {
    func play(_ kind: WKHapticType)
}

final class WatchHapticEngine: HapticEngine {
    func play(_ kind: WKHapticType) {
        WKInterfaceDevice.current().play(kind)
    }
}
