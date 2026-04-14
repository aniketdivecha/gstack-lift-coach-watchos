import SwiftUI

struct RestView: View {
    let exercise: Exercise
    let targetHR: Double
    let onNext: () -> Void

    @State private var currentBPM: Double = 0
    @State private var startTime: Date = Date()
    @State private var isReady: Bool = false

    private let heartRateSource: HeartRateSource?

    init(exercise: Exercise, targetHR: Double = 115, onNext: @escaping () -> Void) {
        self.exercise = exercise
        self.targetHR = targetHR
        self.onNext = onNext
        self.heartRateSource = HealthKitHeartRateSource()
    }

    var body: some View {
        VStack(spacing: 32) {
            // Elapsed timer
            Text(elapsedTime())
                .font(.headline)
                .foregroundColor(.gray)

            // HR display
            if let _ = heartRateSource {
                Text("\(Int(currentBPM)) BPM")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(currentBPM <= targetHR ? .green : .red)

                // Progress bar
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .overlay(
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(currentBPM <= targetHR ? Color.green : Color.red)
                                    .frame(width: min(geo.size.width * progressFraction(), geo.size.width))
                            }
                        )
                }
                .frame(height: 16)
                .padding(.horizontal, 32)
            } else {
                Text("Resting...")
                    .font(.headline)
            }

            // Next button
            Button(action: {
                onNext()
            }) {
                Text(isReady ? "Ready →" : "Waiting...")
                    .font(.headline)
                    .bold()
                    .padding()
                    .frame(width: 120)
                    .background(isReady ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(24)
            }
        }
        .padding()
        .onAppear {
            startTime = Date()
            heartRateSource?.start()
            Task {
                if let bpmStream = heartRateSource?.currentBPM {
                    for await bpm in bpmStream {
                        currentBPM = bpm
                        checkReady()
                    }
                }
            }
        }
        .onDisappear {
            heartRateSource?.stop()
        }
    }

    private func elapsedTime() -> String {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func progressFraction() -> Double {
        guard currentBPM > 0 else { return 0 }
        // Map HR from peak (e.g., 160) to target (115)
        // Simplified: 0% at 160, 100% at 115
        let peakHR = 160.0
        let range = peakHR - targetHR
        let fraction = (peakHR - currentBPM) / range
        return max(0, min(1, fraction))
    }

    private func checkReady() {
        // Ready when HR <= target OR elapsed > 3 minutes
        let elapsed = Date().timeIntervalSince(startTime)
        isReady = currentBPM <= targetHR || elapsed > 180
    }
}

#Preview {
    RestView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onNext: {})
}
