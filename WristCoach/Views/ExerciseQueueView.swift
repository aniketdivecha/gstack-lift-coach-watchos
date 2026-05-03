import SwiftUI

struct ExerciseQueueView: View {
    let exercises: [Exercise]
    let onBegin: () -> Void
    let onSelectExercise: (Int) -> Void

    var body: some View {
        VStack(spacing: 5) {
            Text("Exercises")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(white: 0.40))
                .tracking(0.8)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    queueRow(for: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectExercise(index)
                        }
                }
            }

            Text("Begin workout")
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(Color(red: 0.04, green: 0.52, blue: 1.0))
                .foregroundColor(.white)
                .cornerRadius(10)
                .contentShape(Rectangle())
                .onTapGesture(perform: onBegin)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func queueRow(for exercise: Exercise) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(exercise.name)
                    .font(.system(size: 9.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if metaLabel(for: exercise).isEmpty == false {
                    Text(metaLabel(for: exercise))
                        .font(.system(size: 7.5))
                        .foregroundColor(Color(white: 0.33))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            }
            Spacer(minLength: 4)
            if needsCalibrationBadge(exercise) {
                Text("CAL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
                    .background(Color(red: 0.17, green: 0.08, blue: 0.0))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 9)
        .frame(height: 27)
        .background(Color(white: 0.067))
        .foregroundColor(.white)
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color(white: 0.12), lineWidth: 1)
        )
    }

    private func metaLabel(for exercise: Exercise) -> String {
        switch exercise.id {
        case "tricep_pushdown":
            return ""
        case "bench_press":
            return "135 lb · last session"
        case "chest_fly":
            return "50 lb · last session"
        case "skull_crusher":
            return "40 lb · last session"
        default:
            return exercise.isBodyweight ? "Bodyweight" : "\(Int(exercise.defaultStartingWeight)) lb · last session"
        }
    }

    private func needsCalibrationBadge(_ exercise: Exercise) -> Bool {
        exercise.id == "tricep_pushdown"
    }
}

#Preview {
    ExerciseQueueView(exercises: [], onBegin: {}, onSelectExercise: { _ in })
}
