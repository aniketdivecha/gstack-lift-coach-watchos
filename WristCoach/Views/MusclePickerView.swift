import SwiftUI

struct MusclePickerView: View {
    @State private var selectedGroups: Set<String> = []
    private let library = ExerciseLibrary.load()
    private let onSelectGroup: (String) -> Void
    private let onStartWorkout: () -> Void

    init(
        selectedGroups: Set<String> = [],
        onSelectGroup: @escaping (String) -> Void,
        onStartWorkout: @escaping () -> Void = {}
    ) {
        _selectedGroups = State(initialValue: selectedGroups)
        self.onSelectGroup = onSelectGroup
        self.onStartWorkout = onStartWorkout
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("Today's session")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color(white: 0.40))
                .tracking(0.8)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 5) {
                ForEach(Array(displayGroups.prefix(4)), id: \.id) { group in
                    Button(action: {
                        toggleGroup(group.id)
                    }) {
                        HStack(spacing: 10) {
                            Text(group.name)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Circle()
                                .frame(width: 12, height: 12)
                                .foregroundColor(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : .clear)
                                .overlay(
                                    Circle()
                                        .stroke(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.20), lineWidth: 1.5)
                                )
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color(white: 0.067))
                        .foregroundColor(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : .white)
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }

            Button(action: onStartWorkout) {
                Text("Start →")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 24)
            .background(Color(red: 0.18, green: 0.82, blue: 0.33))
            .foregroundColor(.black)
            .cornerRadius(10)
            .disabled(selectedGroups.isEmpty)
            .opacity(selectedGroups.isEmpty ? 0.45 : 1)
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private var displayGroups: [MuscleGroup] {
        let preferredOrder = ["chest", "triceps", "back", "legs", "shoulders", "biceps", "core"]
        return library.groups.sorted { lhs, rhs in
            let leftIndex = preferredOrder.firstIndex(of: lhs.id) ?? Int.max
            let rightIndex = preferredOrder.firstIndex(of: rhs.id) ?? Int.max
            return leftIndex < rightIndex
        }
    }

    private func toggleGroup(_ group: String) {
        if selectedGroups.contains(group) {
            selectedGroups.remove(group)
        } else {
            selectedGroups.insert(group)
        }
        onSelectGroup(group)
    }
}

#Preview {
    MusclePickerView(onSelectGroup: { _ in })
}
