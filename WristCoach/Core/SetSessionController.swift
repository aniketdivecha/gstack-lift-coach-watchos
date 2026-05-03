import Foundation
import WatchKit

struct SetResult {
    let actualReps: Int
    let repIntervals: [Double]
    let struggled: Bool
    let manualOverride: Bool
}

@MainActor
final class SetSessionController: ObservableObject {
    @Published var repCount: Int = 0
    @Published var isFatigued: Bool = false
    @Published var isCountingStarted = false

    private let exercise: Exercise
    private let targetReps: Int
    private let motionSource: MotionSource
    private let speechAnnouncer: SpeechAnnouncer
    private let hapticEngine: HapticEngine
    private let repDetector: RepDetector
    private let manualMode: Bool
    private let delegate: SetSessionDelegate

    init(
        exercise: Exercise,
        targetReps: Int,
        manualMode: Bool,
        motionSource: MotionSource = CMMotionSource(),
        speechAnnouncer: SpeechAnnouncer = AVSpeechSynthesizerAnnouncer(),
        hapticEngine: HapticEngine = WatchHapticEngine()
    ) {
        self.exercise = exercise
        self.targetReps = targetReps
        self.manualMode = manualMode
        self.motionSource = motionSource
        self.speechAnnouncer = speechAnnouncer
        self.hapticEngine = hapticEngine
        self.repDetector = RepDetector(threshold: exercise.defaultThreshold)
        self.delegate = SetSessionDelegate()
        self.delegate.controller = nil
        self.repDetector.delegate = delegate
        self.delegate.controller = self
    }

    var remainingReps: Int {
        max(targetReps - repCount, 0)
    }

    func start() {
        isCountingStarted = true
        repDetector.reset()
        repCount = 0
        isFatigued = false
        speechAnnouncer.say("Go")
        hapticEngine.play(.start)

        guard manualMode == false else { return }

        motionSource.start { [weak repDetector] t, acceleration in
            repDetector?.processSample(t: t, userAcceleration: acceleration)
        }
    }

    func incrementManualRep() {
        guard manualMode else { return }
        handleRepCount(repCount + 1)
    }

    func decrementManualRep() {
        guard manualMode else { return }
        repCount = max(repCount - 1, 0)
    }

    func stop() -> SetResult {
        motionSource.stop()
        speechAnnouncer.say("\(repCount) reps. Nice work.")
        hapticEngine.play(.success)

        return SetResult(
            actualReps: repCount,
            repIntervals: repDetector.repIntervals,
            struggled: repDetector.lastTwoFatigued.0 && repDetector.lastTwoFatigued.1,
            manualOverride: manualMode
        )
    }

    fileprivate func handleRepCount(_ count: Int) {
        repCount = count
        speechAnnouncer.say(count == 0 ? "" : "\(count)")
        if count == targetReps - 2 {
            speechAnnouncer.say("2 more, push it!")
        } else if count == targetReps - 1 {
            speechAnnouncer.say("Last one, let's go!")
        }
    }

    fileprivate func handleFatigue() {
        guard isFatigued == false else { return }
        isFatigued = true
        speechAnnouncer.say("Come on, you can do it!")
        hapticEngine.play(.notification)
    }
}

private final class SetSessionDelegate: RepDetectorDelegate, @unchecked Sendable {
    weak var controller: SetSessionController?

    nonisolated func repCountDidChange(_ repCount: Int) {
        Task { @MainActor [weak self] in
            self?.controller?.handleRepCount(repCount)
        }
    }

    nonisolated func fatigueDetected() {
        Task { @MainActor [weak self] in
            self?.controller?.handleFatigue()
        }
    }
}
