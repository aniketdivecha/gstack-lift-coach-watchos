import Foundation

extension WorkoutState {
    var selectedMuscleGroups: Set<String> {
        guard case .musclePicker(let selected) = self else { return [] }
        return selected
    }
}
