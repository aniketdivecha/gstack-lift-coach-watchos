import SwiftUI

struct RestView: View {
    let exercise: Exercise
    let nextExercise: Exercise?
    let targetHR: Double
    let degradedHR: Bool
    let onNext: () -> Void

    @State private var currentBPM: Double = 0
    @State private var startTime: Date = Date()
    @State private var isReady: Bool = false
    @State private var now: Date = Date()

    private let heartRateSource: HeartRateSource?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(exercise: Exercise, nextExercise: Exercise? = nil, targetHR: Double = 115, degradedHR: Bool = false, onNext: @escaping () -> Void) {
        self.exercise = exercise
        self.nextExercise = nextExercise
        self.targetHR = targetHR
        self.degradedHR = degradedHR
        self.onNext = onNext
        self.heartRateSource = degradedHR ? nil : HealthKitHeartRateSource()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timer header
            HStack(spacing: 8) {
                Text("ELAPSED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(white: 0.40))
                Spacer()
                Text(elapsedTime())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)

            Text(degradedHR ? elapsedTime() : "\(Int(currentBPM))")
                .font(.system(size: 44, weight: .heavy))
                .foregroundColor(primaryMetricColor)

            Text(degradedHR ? "TIMER ONLY" : "BPM ♥")
                .font(.system(size: 11))
                .foregroundColor(primaryMetricColor.opacity(0.75))
                .padding(.bottom, 10)

            // Target
            HStack(spacing: 0) {
                Text(degradedHR ? "No HR " : "Target ")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.33))
                Text(degradedHR ? "90s rest" : "\(Int(targetHR)) BPM")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.67))
                if isReady {
                    Text(" ✓")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                }
            }
            .padding(.bottom, 8)

            // Progress bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.11))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: max(0, proxy.size.width * progressFraction()))
                }
            }
            .frame(height: 4)
            .padding(.bottom, 12)

            // Ready button
            Button(action: onNext) {
                Text("Ready →")
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(isReady ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.11))
            .foregroundColor(isReady ? .black : Color(white: 0.27))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isReady ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.20), lineWidth: 1.5)
            )
            .buttonStyle(.plain)

            Text(nextPreview)
                .font(.system(size: 9))
                .foregroundColor(Color(white: 0.33))
                .padding(.top, 6)
                .lineLimit(1)

            Spacer()
        }
        .padding(16)
        .onAppear {
            startTime = Date()
            now = startTime
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
        .onReceive(timer) { date in
            now = date
            checkReady()
        }
    }

    private var primaryMetricColor: Color {
        isReady ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(red: 1.0, green: 0.22, blue: 0.37)
    }

    private var progressColor: Color {
        isReady ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(red: 1.0, green: 0.22, blue: 0.37)
    }

    private var nextPreview: String {
        guard let nextExercise else { return "Last exercise" }
        let weight = nextExercise.isBodyweight ? "Bodyweight" : "\(Int(nextExercise.defaultStartingWeight)) lb"
        return "Next: \(nextExercise.name) · \(weight)"
    }

    private func elapsedTime() -> String {
        let elapsed = Int(now.timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func progressFraction() -> Double {
        guard degradedHR == false else {
            let elapsed = now.timeIntervalSince(startTime)
            return max(0, min(1, elapsed / 90.0))
        }
        guard currentBPM > 0 else { return 0 }
        let peakHR = 160.0
        let range = peakHR - targetHR
        let fraction = (peakHR - currentBPM) / range
        return max(0, min(1, fraction))
    }

    private func checkReady() {
        let elapsed = now.timeIntervalSince(startTime)
        isReady = degradedHR ? elapsed >= 90 : (currentBPM <= targetHR || elapsed > 180)
    }
}

#Preview {
    RestView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onNext: {})
}
