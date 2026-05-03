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
        VStack(spacing: 10) {
            // Header
            Text("Calibration")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                .tracking(0.8)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Exercise name
            Text(exercise.name)
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Instructions
            Text("Set weight where **rep 7–8 is very hard.** Last 1–2 should be a real struggle.")
                .font(.system(size: 9.5))
                .foregroundColor(Color(white: 0.53))
                .multilineTextAlignment(.center)
                .lineSpacing(1.5)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 4)

            if exercise.isBodyweight {
                Button("Start 8 reps") {
                    onComplete(0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(white: 0.67))
                    }
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color(white: 0.11)))
                    .overlay(Circle().stroke(Color(white: 0.20), lineWidth: 1))
                    .buttonStyle(.plain)

                    Spacer()

                    // Weight value
                    VStack(spacing: 1) {
                        Text("\(Int(currentWeight))")
                            .font(.system(size: 28, weight: .bold))
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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(white: 0.67))
                    }
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color(white: 0.11)))
                    .overlay(Circle().stroke(Color(white: 0.20), lineWidth: 1))
                    .buttonStyle(.plain)
                }
                .frame(height: 34)

                Spacer().frame(height: 4)

                // Start button
                Button("Start 8 reps") {
                    onComplete(currentWeight)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(.black)
                .font(.system(size: 12, weight: .bold))
                .cornerRadius(10)
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
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
