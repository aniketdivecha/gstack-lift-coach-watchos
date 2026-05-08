import SwiftUI

struct ExerciseQueueView: View {
    let exercises: [Exercise]
    let onBegin: ([Exercise]) -> Void
    let onEndWorkout: (() -> Void)?

    @State private var queuedExercises: [Exercise]
    @State private var selectedExerciseIDs: Set<String>
    @State private var draggingExerciseID: String?

    init(
        exercises: [Exercise],
        onBegin: @escaping ([Exercise]) -> Void,
        onEndWorkout: (() -> Void)? = nil
    ) {
        self.exercises = exercises
        self.onBegin = onBegin
        self.onEndWorkout = onEndWorkout
        _queuedExercises = State(initialValue: exercises)
        _selectedExerciseIDs = State(initialValue: Set(exercises.map(\.id)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Exercises")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(white: 0.40))
                        .tracking(0.8)
                        .textCase(.uppercase)
                    Spacer()
                    Button(action: toggleSelectAll) {
                        Text(allSelected ? "Clear" : "All")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 40, height: 22)
                    }
                    .background(Color(white: 0.11))
                    .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(white: 0.20), lineWidth: 1)
                    )
                    .buttonStyle(.plain)
                }

                VStack(spacing: 7) {
                    ForEach(Array(queuedExercises.enumerated()), id: \.element.id) { index, exercise in
                        queueRow(for: exercise)
                            .scaleEffect(draggingExerciseID == exercise.id ? 1.03 : 1)
                            .opacity(draggingExerciseID == exercise.id ? 0.88 : 1)
                            .zIndex(draggingExerciseID == exercise.id ? 1 : 0)
                            .gesture(reorderGesture(for: exercise, at: index))
                            .animation(.easeOut(duration: 0.12), value: draggingExerciseID)
                    }
                }

                Button(action: beginSelectedWorkout) {
                    Text("Begin workout")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 32)
                .background(selectedExercises.isEmpty ? Color(white: 0.11) : Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(selectedExercises.isEmpty ? Color(white: 0.35) : .black)
                .cornerRadius(10)
                .buttonStyle(.plain)
                .disabled(selectedExercises.isEmpty)

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
        .onChange(of: exercises.map(\.id)) { _, _ in
            queuedExercises = exercises
            selectedExerciseIDs = Set(exercises.map(\.id))
        }
    }

    private func queueRow(for exercise: Exercise) -> some View {
        let selected = selectedExerciseIDs.contains(exercise.id)

        return HStack(spacing: 10) {
            Circle()
                .fill(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color.clear)
                .frame(width: 17, height: 17)
                .overlay(
                    Circle()
                        .stroke(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.25), lineWidth: 1.5)
                )
                .contentShape(Circle())
                .onTapGesture {
                    toggleExercise(exercise.id)
                }

            Text(exercise.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(white: 0.067))
        .foregroundColor(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : .white)
        .cornerRadius(9)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.12), lineWidth: 1)
        )
    }

    private var selectedExercises: [Exercise] {
        queuedExercises.filter { selectedExerciseIDs.contains($0.id) }
    }

    private var allSelected: Bool {
        selectedExerciseIDs.count == queuedExercises.count
    }

    private func toggleExercise(_ exerciseID: String) {
        if selectedExerciseIDs.contains(exerciseID) {
            selectedExerciseIDs.remove(exerciseID)
        } else {
            selectedExerciseIDs.insert(exerciseID)
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedExerciseIDs.removeAll()
        } else {
            selectedExerciseIDs = Set(queuedExercises.map(\.id))
        }
    }

    private func reorderGesture(for exercise: Exercise, at index: Int) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { _ in
                draggingExerciseID = exercise.id
            }
            .onEnded { value in
                defer { draggingExerciseID = nil }
                let rowStride: CGFloat = 41
                let offset = Int((value.translation.height / rowStride).rounded())
                guard offset != 0 else { return }

                let destination = max(0, min(queuedExercises.count - 1, index + offset))
                guard destination != index,
                      queuedExercises.indices.contains(index) else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.18)) {
                    let draggedExercise = queuedExercises.remove(at: index)
                    queuedExercises.insert(draggedExercise, at: destination)
                }
            }
    }

    private func beginSelectedWorkout() {
        let selected = selectedExercises
        guard selected.isEmpty == false else { return }
        onBegin(selected)
    }
}

#Preview {
    ExerciseQueueView(exercises: [], onBegin: { _ in })
}
