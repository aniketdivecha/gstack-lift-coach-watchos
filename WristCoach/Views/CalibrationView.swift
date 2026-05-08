import SwiftUI

struct CalibrationView: View {
    let exercise: Exercise
    @State private var currentWeight: Double
    @State private var attemptCount: Int = 0
    @StateObject private var calibrationController = CalibrationCaptureController()
    let onComplete: (Double, RepMotionSignature?) -> Void
    let onManualEntry: () -> Void

    init(
        exercise: Exercise,
        currentWeight: Double? = nil,
        attemptCount: Int = 0,
        onComplete: @escaping (Double, RepMotionSignature?) -> Void,
        onManualEntry: @escaping () -> Void
    ) {
        self.exercise = exercise
        self._currentWeight = State(initialValue: currentWeight ?? exercise.defaultStartingWeight)
        self.onComplete = onComplete
        self.onManualEntry = onManualEntry
    }

    var body: some View {
        VStack(spacing: 6) {
            // Header
            Text("Calibration")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                .tracking(0.8)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Exercise name
            Text(exercise.name)
                .font(.system(size: 14.5, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Instructions
            Text("Set weight where **rep 7–8 is very hard.** Last 1–2 should be a real struggle.")
                .font(.system(size: 9))
                .foregroundColor(Color(white: 0.53))
                .multilineTextAlignment(.center)
                .lineSpacing(0.5)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 2)

            if exercise.isBodyweight {
                Button("Start 8 reps") {
                    onComplete(0, nil)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(.black)
                .font(.system(size: 12, weight: .bold))
                .cornerRadius(10)
                .buttonStyle(.plain)
            } else {
                // Weight control row
                HStack(spacing: 0) {
                    // Minus button
                    Button(action: {
                        currentWeight = max(currentWeight - weightIncrement(), exercise.minimumWeight)
                    }) {
                        Text("−")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(white: 0.67))
                    }
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(white: 0.11)))
                    .overlay(Circle().stroke(Color(white: 0.20), lineWidth: 1))
                    .buttonStyle(.plain)

                    Spacer()

                    // Weight value
                    VStack(spacing: 1) {
                        Text("\(Int(currentWeight))")
                            .font(.system(size: 26, weight: .bold))
                            .lineSpacing(-4)
                        Text("lb")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.33))
                    }

                    Spacer()

                    // Plus button
                    Button(action: {
                        currentWeight = currentWeight + weightIncrement()
                    }) {
                        Text("+")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(white: 0.67))
                    }
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(white: 0.11)))
                    .overlay(Circle().stroke(Color(white: 0.20), lineWidth: 1))
                    .buttonStyle(.plain)
                }
                .frame(height: 30)
                .opacity(calibrationController.isRecording ? 0.45 : 1)
                .disabled(calibrationController.isRecording)

                Spacer().frame(height: 2)

                if calibrationController.isRecording {
                    Text("\(calibrationController.repCount)/8 reps")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color(white: 0.11))
                        .cornerRadius(10)
                } else {
                    Button("Start 8 reps") {
                        startCalibration()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                    .foregroundColor(.black)
                    .font(.system(size: 12, weight: .bold))
                    .cornerRadius(10)
                    .buttonStyle(.plain)
                }

                if let errorMessage = calibrationController.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onDisappear {
            calibrationController.stop()
        }
    }

    private func weightIncrement() -> Double {
        // Small muscle groups = 2.5 lb, large = 5 lb
        let group = exercise.muscleGroups.first ?? ""
        switch group {
        case "legs":
            return 5.0
        case "chest", "back":
            return 5.0
        default:
            return 2.5
        }
    }

    private func startCalibration() {
        calibrationController.start(
            targetReps: 8,
            threshold: exercise.defaultThreshold
        ) { motionSignature in
            onComplete(currentWeight, motionSignature)
        }
    }
}

final class CalibrationCaptureController: ObservableObject, @unchecked Sendable {
    @Published private(set) var isRecording = false
    @Published private(set) var repCount = 0
    @Published private(set) var errorMessage: String?

    private let motionSource: MotionSource
    private var collector: RepCalibrationCollector?
    private var completion: ((RepMotionSignature?) -> Void)?
    private var targetRepCount = 0
    private var hasCompleted = false

    init(motionSource: MotionSource = CMMotionSource()) {
        self.motionSource = motionSource
    }

    func start(
        targetReps: Int,
        threshold: Double,
        onComplete: @escaping (RepMotionSignature?) -> Void
    ) {
        guard motionSource.isAvailable else {
            errorMessage = "Motion unavailable"
            return
        }

        repCount = 0
        errorMessage = nil
        isRecording = true
        hasCompleted = false
        targetRepCount = targetReps
        completion = onComplete
        collector = RepCalibrationCollector(targetReps: targetReps, threshold: threshold)

        motionSource.start { [weak self] t, acceleration in
            guard let self, let collector = self.collector else {
                return
            }

            if let signature = collector.processSample(t: t, userAcceleration: acceleration) {
                self.finish(with: signature)
                return
            }

            let count = collector.repCount
            Task { @MainActor [weak self] in
                self?.repCount = count
            }
        }
    }

    func stop() {
        motionSource.stop()
        collector = nil
        completion = nil
        isRecording = false
        hasCompleted = false
    }

    private func finish(with signature: RepMotionSignature) {
        guard hasCompleted == false else {
            return
        }

        hasCompleted = true
        motionSource.stop()

        Task { @MainActor [weak self] in
            guard let self else { return }

            self.repCount = self.targetRepCount
            self.isRecording = false
            self.collector = nil
            let completion = self.completion
            self.completion = nil
            completion?(signature)
        }
    }
}

#Preview {
    CalibrationView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onComplete: { _, _ in }, onManualEntry: {})
}
