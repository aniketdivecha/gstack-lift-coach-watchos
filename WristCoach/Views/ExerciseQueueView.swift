import SwiftUI
import WatchKit

struct ExerciseQueueView: View {
    let exercises: [Exercise]
    let onBegin: ([Exercise]) -> Void

    @State private var queuedExercises: [Exercise]
    @State private var selectedExerciseIDs: Set<String>
    @State private var draggingExerciseID: String?

    init(exercises: [Exercise], onBegin: @escaping ([Exercise]) -> Void) {
        self.exercises = exercises
        self.onBegin = onBegin
        _queuedExercises = State(initialValue: exercises)
        _selectedExerciseIDs = State(initialValue: Set(exercises.map(\.id)))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
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

                    ScrollView {
                        VStack(spacing: 5) {
                            ForEach(Array(queuedExercises.enumerated()), id: \.element.id) { index, exercise in
                                queueRow(for: exercise)
                                    .scaleEffect(draggingExerciseID == exercise.id ? 1.03 : 1)
                                    .opacity(draggingExerciseID == exercise.id ? 0.88 : 1)
                                    .zIndex(draggingExerciseID == exercise.id ? 1 : 0)
                                    .gesture(reorderGesture(for: exercise, at: index))
                                    .animation(.easeOut(duration: 0.12), value: draggingExerciseID)
                            }
                        }
                        .padding(.bottom, 46)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Button(action: beginSelectedWorkout) {
                    Text("Begin workout")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 34)
                .background(selectedExercises.isEmpty ? Color(white: 0.11) : Color(red: 0.04, green: 0.52, blue: 1.0))
                .foregroundColor(selectedExercises.isEmpty ? Color(white: 0.35) : .white)
                .cornerRadius(11)
                .buttonStyle(.plain)
                .disabled(selectedExercises.isEmpty)
            }
            .frame(width: proxy.size.width, height: max(proxy.size.height, screenHeight), alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: exercises.map(\.id)) { _, _ in
            queuedExercises = exercises
            selectedExerciseIDs = Set(exercises.map(\.id))
        }
    }

    private func queueRow(for exercise: Exercise) -> some View {
        let selected = selectedExerciseIDs.contains(exercise.id)

        return HStack(spacing: 6) {
            Circle()
                .fill(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color.clear)
                .frame(width: 15, height: 15)
                .overlay(
                    Circle()
                        .stroke(selected ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.25), lineWidth: 1.4)
                )
                .contentShape(Circle())
                .onTapGesture {
                    toggleExercise(exercise.id)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(exercise.name)
                    .font(.system(size: 9.8, weight: .semibold))
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

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(white: 0.48))
                .frame(width: 20, height: 24)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .frame(height: 33)
        .background(Color(white: 0.067))
        .foregroundColor(selected ? .white : Color(white: 0.48))
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(selected ? Color(red: 0.18, green: 0.82, blue: 0.33).opacity(0.65) : Color(white: 0.12), lineWidth: 1)
        )
    }

    private func metaLabel(for exercise: Exercise) -> String {
        switch exercise.id {
        case "tricep_cable_pushdown":
            return ""
        case "bench_press":
            return "50 lb · last session"
        case "chest_fly":
            return "80 lb · last session"
        case "skull_crusher":
            return "40 lb · last session"
        default:
            return exercise.isBodyweight ? "Bodyweight" : "\(Int(exercise.defaultStartingWeight)) lb · last session"
        }
    }

    private var selectedExercises: [Exercise] {
        queuedExercises.filter { selectedExerciseIDs.contains($0.id) }
    }

    private var allSelected: Bool {
        selectedExerciseIDs.count == queuedExercises.count
    }

    private var screenHeight: CGFloat {
        max(0, WKInterfaceDevice.current().screenBounds.height - 52)
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
