import SwiftUI

struct SessionSummaryView: View {
    let exercises: [Exercise]
    let records: [ExerciseRecord]
    let displayVolumeOverride: Double?
    let onDone: () -> Void

    init(exercises: [Exercise], records: [ExerciseRecord], displayVolumeOverride: Double? = nil, onDone: @escaping () -> Void) {
        self.exercises = exercises
        self.records = records
        self.displayVolumeOverride = displayVolumeOverride
        self.onDone = onDone
    }

    private var totalVolume: Double {
        if let displayVolumeOverride {
            return displayVolumeOverride
        }
        return records.reduce(0) { $0 + Double($1.actualReps) * $1.targetWeight }
    }

    var body: some View {
        VStack(spacing: 3) {
            Text("Session done")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(white: 0.40))
                .tracking(0.8)
                .textCase(.uppercase)

            Text(formatVolume(totalVolume))
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("lbs total volume")
                .font(.system(size: 8.5))
                .foregroundColor(Color(white: 0.27))
                .padding(.bottom, 2)

            VStack(spacing: 3) {
                ForEach(records.prefix(5), id: \.exerciseId) { record in
                    HStack(spacing: 8) {
                        Text(exerciseName(for: record.exerciseId))
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 4)
                        Text(resultLabel(for: record))
                            .font(.system(size: 7.5, weight: record.actualReps > record.targetReps ? .bold : .regular))
                            .foregroundColor(resultColor(for: record))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .frame(height: 21)
                    .background(Color(white: 0.053))
                    .cornerRadius(7)
                }
            }

            Button(action: onDone) {
                Text("Done ✓")
                    .font(.system(size: 10.5, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 25)
            .background(Color(white: 0.11))
            .foregroundColor(Color(white: 0.67))
            .cornerRadius(8)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
