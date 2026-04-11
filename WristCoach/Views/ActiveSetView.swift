import SwiftUI
import CoreMotion

class RepCountObservable: ObservableObject {
    @Published var repCount: Int = 0
    @Published var remaining: Int = 0
    @Published var isFatigued: Bool = false
    @Published var repIntervals: [Double] = []

    func update(repCount: Int, remaining: Int, isFatigued: Bool, repIntervals: [Double]) {
        self.repCount = repCount
        self.remaining = remaining
        self.isFatigued = isFatigued
        self.repIntervals = repIntervals
    }
}

struct ActiveSetView: View {
    @StateObject var repObservable: RepCountObservable
    let exercise: Exercise
    let targetReps: Int
    let onRepCountUpdate: (Int, [Double], Bool) -> Void
    let onStop: () -> Void

    private let motionSource: MotionSource
    private let speechAnnouncer: SpeechAnnouncer
    private let hapticEngine: HapticEngine
    private let clock: Clock
    private var repDetector: RepDetector?

    init(
        exercise: Exercise,
        targetReps: Int,
        onRepCountUpdate: @escaping (Int, [Double], Bool) -> Void,
        onStop: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.targetReps = targetReps
        self.onRepCountUpdate = onRepCountUpdate
        self.onStop = onStop
        self._repObservable = StateObject(wrappedValue: RepCountObservable())
        self.motionSource = CMMotionSource()
        self.speechAnnouncer = AVSpeechSynthesizerAnnouncer()
        self.hapticEngine = WatchHapticEngine()
        self.clock = MonotonicClock()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top info
            HStack {
                Text(exercise.name)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Set \(exercise.isBodyweight ? "Bodyweight" : "Calibrate")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Rep counter
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 24)
                    .frame(width: 200, height: 200)

                Text("\(repObservable.repCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(isFatigued ? Color.yellow : Color.white)

                Circle()
                    .stroke(Color.blue, lineWidth: 24)
                    .frame(width: 200, height: 200)
                    .opacity(max(0, min(1, Double(repObservable.repCount) / Double(targetReps))))
            }
            .padding()

            // Progress text
            Text(remainingText())
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom)

            // GO/STOP buttons
            HStack(spacing: 20) {
                if repObservable.repCount == 0 {
                    Button("GO") {
                        startRepDetection()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(32)
                }

                if repObservable.repCount > 0 {
                    Button("STOP") {
                        stopRepDetection()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(32)
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            repDetector = RepDetector(threshold: exercise.defaultThreshold)
            repDetector?.delegate = self
        }
        .onDisappear {
            motionSource.stop()
        }
    }

    private func remainingText() -> String {
        let remaining = targetReps - repObservable.repCount
        switch remaining {
        case 2:
            return "2 more, push it!"
        case 1:
            return "Last one, let's go!"
        case 0:
            return "Nice work!"
        default:
            return "\(remaining) reps remaining"
        }
    }

    private func startRepDetection() {
        motionSource.start { [weak self] t, acceleration in
            guard let self = self, let detector = self.repDetector else { return }
            detector.processSample(t: t, userAcceleration: acceleration)
        }
        speechAnnouncer.say("Go")
        hapticEngine.play(.start)
    }

    private func stopRepDetection() {
        motionSource.stop()
        speechAnnouncer.say("Stop")
        hapticEngine.play(.stop)
        onStop()
    }

    private var isFatigued: Bool {
        repObservable.isFatigued
    }
}

extension ActiveSetView: RepDetectorDelegate {
    func repCountDidChange(_ repCount: Int) {
        let remaining = max(0, targetReps - repCount)
        let isFatigued = repObservable.isFatigued

        speechAnnouncer.say(repCount == 0 ? "" : "\(repCount)")
        if repCount == targetReps - 2 {
            speechAnnouncer.say("2 more, push it!")
        } else if repCount == targetReps - 1 {
            speechAnnouncer.say("Last one, let's go!")
        }

        repObservable.update(
            repCount: repCount,
            remaining: remaining,
            isFatigued: isFatigued,
            repIntervals: repDetector?.repIntervals ?? []
        )
    }

    func fatigueDetected() {
        speechAnnouncer.say("Come on, you can do it!")
        hapticEngine.play(.warning)
        repObservable.isFatigued = true
    }

    func setComplete(_ actualReps: Int, _ repIntervals: [Double], _ struggled: Bool) {
        speechAnnouncer.say("\(actualReps) reps. Nice work.")
        hapticEngine.play(.success)
        onRepCountUpdate(actualReps, repIntervals, struggled)
    }
}

#Preview {
    ActiveSetView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), targetReps: 8, onRepCountUpdate: { _, _, _ in }, onStop: {})
}
