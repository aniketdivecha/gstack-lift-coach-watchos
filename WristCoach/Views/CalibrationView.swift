import SwiftUI

struct CalibrationView: View {
    let exercise: Exercise
    @State private var currentWeight: Double
    @State private var attemptCount: Int = 0
    let onComplete: (Double) -> Void
    let onManualEntry: () -> Void

    init(exercise: Exercise, currentWeight: Double? = nil, attemptCount: Int = 0, onComplete: @escaping (Double) -> Void, onManualEntry: @escaping () -> Void) {
        self.exercise = exercise
        self._currentWeight = State(initialValue: currentWeight ?? exercise.defaultStartingWeight)
        self.onComplete = onComplete
        self.onManualEntry = onManualEntry
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Calibrate: \(exercise.name)")
                    .font(.title2)
                    .bold()
                Text("Find weight where rep 7-8 is very hard")
                    .font(.body)
                    .multilineTextAlignment(.center)

                if exercise.isBodyweight {
                    VStack(spacing: 16) {
                        Text("Bodyweight exercise")
                            .font(.headline)
                        Text("Do 8 reps now")
                            .font(.title)
                            .bold()
                        Button("Start 8 reps") {
                            onComplete(0)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Weight: \(Int(currentWeight)) lb")
                            .font(.title)
                            .bold()
                        HStack {
                            Button("-") {
                                currentWeight = max(currentWeight - weightIncrement(), exercise.minimumWeight)
                            }
                            Button("+") {
                                currentWeight = currentWeight + weightIncrement()
                            }
                        }
                        .buttonStyle(CircularButtonStyle())
                        Button("Start 8 reps") {
                            onComplete(currentWeight)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("Calibration")
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
}

#Preview {
    CalibrationView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onComplete: { _ in }, onManualEntry: {})
}

struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(Circle().fill(configuration.isPressed ? Color.gray : Color.blue))
            .foregroundColor(.white)
    }
}
