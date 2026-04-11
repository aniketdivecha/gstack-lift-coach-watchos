import SwiftUI

struct ExerciseQueueView: View {
    let exercises: [Exercise]
    let onBegin: () -> Void
    let onSelectExercise: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    Button(action: {
                        onSelectExercise(index)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.body)
                                    .bold()
                                Text(exercise.isBodyweight ? "Bodyweight" : "Calibrate")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if index == 0 {
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercise Queue")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: onBegin) {
                        Text("Begin workout")
                            .bold()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseQueueView(exercises: [], onBegin: {}, onSelectExercise: { _ in })
}
