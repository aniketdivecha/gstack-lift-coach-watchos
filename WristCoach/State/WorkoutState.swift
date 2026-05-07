import Foundation

enum WorkoutState {
    case idle
    case musclePicker(selected: Set<String>)
    case exerciseQueue(exercises: [Exercise], currentExerciseIndex: Int)
    case calibration(exercises: [Exercise], currentExerciseIndex: Int, exercise: Exercise, currentWeight: Double, attemptCount: Int)
    case workoutReadiness(exercises: [Exercise], currentExerciseIndex: Int, exercise: Exercise, readiness: WorkoutReadiness)
    case activeSet(exercise: Exercise, targetReps: Int, readiness: WorkoutReadiness, initialWeight: Double)
    case setComplete(exercises: [Exercise], currentExerciseIndex: Int, exercise: Exercise, result: SetResult, overload: OverloadResult, targetReps: Int, readiness: WorkoutReadiness)
    case rest(exercises: [Exercise], currentExerciseIndex: Int, exercise: Exercise, startTime: Date, targetHR: Double, degradedHR: Bool)
    case sessionSummary(exercises: [Exercise], records: [ExerciseRecord])
}

extension WorkoutState {
    var isWorkoutActive: Bool {
        switch self {
        case .workoutReadiness, .activeSet, .setComplete, .rest:
            return true
        default:
            return false
        }
    }
}
