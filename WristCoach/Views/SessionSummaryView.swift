import SwiftUI

struct SessionSummaryView: View {
    let exercises: [Exercise]
    let records: [ExerciseRecord]
    let displayVolumeOverride: Double?
    let onDone: () -> Void
    let onEndWorkout: (() -> Void)?

    init(
        exercises: [Exercise],
        records: [ExerciseRecord],
        displayVolumeOverride: Double? = nil,
        onDone: @escaping () -> Void,
        onEndWorkout: (() -> Void)? = nil
    ) {
        self.exercises = exercises
        self.records = records
        self.displayVolumeOverride = displayVolumeOverride
        self.onDone = onDone
        self.onEndWorkout = onEndWorkout
    }

    private var totalVolume: Double {
        if let displayVolumeOverride {
            return displayVolumeOverride
        }
        return records.reduce(0) { $0 + Double($1.actualReps) * $1.targetWeight }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Session done")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(white: 0.40))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatVolume(totalVolume))
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("lbs total volume")
                    .font(.system(size: 8.5))
                    .foregroundColor(Color(white: 0.27))

                VStack(spacing: 7) {
                    ForEach(records.prefix(5), id: \.exerciseId) { record in
                        HStack(spacing: 10) {
                            Text(exerciseName(for: record.exerciseId))
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .layoutPriority(1)
                            Text(resultLabel(for: record))
                                .font(.system(size: 10, weight: record.actualReps > record.targetReps ? .bold : .regular))
                                .foregroundColor(resultColor(for: record))
                                .lineLimit(1)
                                .frame(minWidth: 54, alignment: .trailing)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: 0.067))
                        .foregroundColor(.white)
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color(white: 0.12), lineWidth: 1)
                        )
                    }
                }

                Button(action: onDone) {
                    Text("Done ✓")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 32)
                .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(.plain)

                if let onEndWorkout {
                    Button(action: onEndWorkout) {
                        Text("End Workout")
                            .font(.system(size: 10, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 32)
                    .background(Color(red: 1.0, green: 0.27, blue: 0.23))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? String(format: "%.0f", volume)
    }

    private func resultLabel(for record: ExerciseRecord) -> String {
        if record.actualReps > record.targetReps {
            return "PR ↑"
        }

        let weight = record.targetWeight > 0 ? "\(Int(record.targetWeight)) lb × " : ""
        return "\(weight)\(record.actualReps)"
    }

    private func resultColor(for record: ExerciseRecord) -> Color {
        if record.actualReps > record.targetReps {
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        }
        return Color(white: 0.33)
    }

    private func exerciseName(for exerciseId: String) -> String {
        let library = ExerciseLibrary.load()
        for group in library.groups {
            if let exercise = group.exercises.first(where: { $0.id == exerciseId }) {
                return exercise.name
            }
        }
        return exerciseId
    }
}

#Preview {
    SessionSummaryView(exercises: [], records: [], onDone: {})
}
