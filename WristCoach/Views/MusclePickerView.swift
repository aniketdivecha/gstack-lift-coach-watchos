import SwiftUI

struct MusclePickerView: View {
    @State private var selectedGroups: Set<String> = []
    private let library = ExerciseLibrary.load()
    private let onSelectGroup: (String) -> Void

    init(onSelectGroup: @escaping (String) -> Void) {
        self.onSelectGroup = onSelectGroup
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.groups) { group in
                    Section(header: Text(group.name)) {
                        ForEach(group.exercises) { exercise in
                            Button(action: {
                                toggleGroup(group.id)
                            }) {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    if selectedGroups.contains(group.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Muscles")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        onSelectGroup(Array(selectedGroups).first ?? "")
                    }) {
                        Text("Start →")
                            .bold()
                    }
                    .disabled(selectedGroups.count < 1)
                }
            }
        }
    }

    private func toggleGroup(_ group: String) {
        if selectedGroups.contains(group) {
            selectedGroups.remove(group)
        } else {
            selectedGroups.insert(group)
            onSelectGroup(group)
        }
    }
}

#Preview {
    MusclePickerView(onSelectGroup: { _ in })
}
