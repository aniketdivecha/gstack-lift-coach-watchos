import SwiftUI

struct SessionSummaryView: View {
    let exercises: [Exercise]
    let records: [ExerciseRecord]
    let onDone: () -> Void

    private var totalVolume: Double {
        records.reduce(0) { $0 + Double($1.actualReps) * $1.targetWeight }
    }

    private var newPRs: [ExerciseRecord] {
        records.filter { record in
            // Check if this is a new PR for this exercise
            let previousRecords = records.filter { $0.exerciseId == record.exerciseId }
            guard let prevRecord = previousRecords.sorted(by: { $0.date < $1.date }).first else {
                return false
            }
            return prevRecord.date == record.date
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            // Total volume
            HStack {
                Text("Total Volume")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(formatVolume(totalVolume))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            // PR badges
            if !newPRs.isEmpty {
                HStack(spacing: 16) {
                    ForEach(newPRs.prefix(3), id: \.exerciseId) { record in
                        VStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(record.actualReps.description)
                                .font(.caption)
                        }
                    }
                }
            }

            // Exercise list
            List(records.prefix(5)) { record in
                HStack {
                    Text(exerciseName(for: record.exerciseId))
                        .font(.body)
                    Spacer()
                    Text("\(record.actualReps) reps @ \(Int(record.targetWeight)) lb")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Done button
            Button("Done") {
                onDone()
            }
            .padding()
            .frame(width: 120)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(22)
        }
        .padding()
        .navigationTitle("Workout Complete")
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatted = volume >= 1000 ? String(format: "%.0f", volume / 1000) + " K" : String(format: "%.0f", volume)
        return "\(formatted) lbs"
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
