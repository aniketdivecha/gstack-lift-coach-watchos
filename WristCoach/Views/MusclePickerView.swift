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
        ScrollView {
            VStack(spacing: 8) {
                Text("Today's session")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(white: 0.40))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 7) {
                    ForEach(displayGroups, id: \.id) { group in
                        Button(action: {
                            toggleGroup(group.id)
                        }) {
                            HStack(spacing: 10) {
                                Text(group.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Circle()
                                    .frame(width: 17, height: 17)
                                    .foregroundColor(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : .clear)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedGroups.contains(group.id) ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.20), lineWidth: 1.5)
                                    )
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
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
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 32)
                .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(.black)
                .cornerRadius(10)
                .disabled(selectedGroups.isEmpty)
                .opacity(selectedGroups.isEmpty ? 0.45 : 1)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayGroups: [MuscleGroup] {
        let preferredOrder = ["chest", "tricep", "back", "legs", "shoulders", "biceps"]
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
