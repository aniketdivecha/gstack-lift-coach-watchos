import Foundation

enum WorkoutState {
    case idle
    case musclePicker(selected: Set<String>)
    case exerciseQueue(exercises: [Exercise], currentExerciseIndex: Int)
    case calibration(exercise: Exercise, currentWeight: Double, attemptCount: Int)
    case activeSet(exercise: Exercise, targetReps: Int, repDetector: RepDetector)
    case rest(exercise: Exercise, startTime: Date, targetHR: Double)
    case sessionSummary(exercises: [Exercise], records: [ExerciseRecord])
}

extension WorkoutState {
    var isWorkoutActive: Bool {
        switch self {
        case .activeSet, .rest:
            return true
        default:
            return false
        }
    }
}
