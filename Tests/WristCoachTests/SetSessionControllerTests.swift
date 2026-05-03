import Testing
import WatchKit

@MainActor
@Suite("SetSessionController")
struct SetSessionControllerTests {
    @Test("manual mode owns final set result")
    func manualModeOwnsFinalSetResult() {
        let motion = FakeMotionSource()
        let speech = SpySpeechAnnouncer()
        let haptics = SpyHapticEngine()
        let controller = SetSessionController(
            exercise: .benchPressFixture,
            targetReps: 8,
            manualMode: true,
            motionSource: motion,
            speechAnnouncer: speech,
            hapticEngine: haptics
        )

        controller.start()
        controller.incrementManualRep()
        controller.incrementManualRep()
        controller.incrementManualRep()
        controller.decrementManualRep()
        controller.incrementManualRep()
        let result = controller.stop()

        #expect(motion.didStart == false)
        #expect(motion.didStop == true)
        #expect(result.actualReps == 3)
        #expect(result.manualOverride == true)
        #expect(result.repIntervals.isEmpty)
        #expect(result.struggled == false)
        #expect(speech.spoken.first == "Go")
        #expect(speech.spoken.contains("3 reps. Nice work."))
        #expect(haptics.played.contains(.success))
    }

    @Test("motion mode starts motion source and returns detector-owned counts")
    func motionModeStartsMotionSource() {
        let motion = FakeMotionSource()
        let speech = SpySpeechAnnouncer()
        let haptics = SpyHapticEngine()
        let controller = SetSessionController(
            exercise: .benchPressFixture,
            targetReps: 8,
            manualMode: false,
            motionSource: motion,
            speechAnnouncer: speech,
            hapticEngine: haptics
        )

        controller.start()
        let result = controller.stop()

        #expect(motion.didStart == true)
        #expect(motion.didStop == true)
        #expect(result.actualReps == 0)
        #expect(result.manualOverride == false)
    }
}

private final class FakeMotionSource: MotionSource {
    var isAvailable = true
    var didStart = false
    var didStop = false

    func start(onSample: @escaping (TimeInterval, SIMD3<Double>) -> Void) {
        didStart = true
    }

    func stop() {
        didStop = true
    }
}

private final class SpySpeechAnnouncer: SpeechAnnouncer {
    var spoken: [String] = []
    var didPrewarm = false

    func say(_ text: String) {
        spoken.append(text)
    }

    func prewarm() {
        didPrewarm = true
    }
}

private final class SpyHapticEngine: HapticEngine {
    var played: [WKHapticType] = []

    func play(_ kind: WKHapticType) {
        played.append(kind)
    }
}

extension Exercise {
    static let benchPressFixture = Exercise(
        id: "bench_press",
        name: "Bench Press",
        muscleGroups: ["chest", "triceps"],
        defaultThreshold: 0.4,
        increment: Increments(small: 2.5, large: 5.0),
        isBodyweight: false,
        isIsometric: false,
        weightType: .free,
        minimumWeight: 2.5,
        defaultStartingWeight: 45.0
    )
}
