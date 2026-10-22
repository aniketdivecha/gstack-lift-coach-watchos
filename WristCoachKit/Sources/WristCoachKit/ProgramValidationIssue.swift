import Foundation

public enum ProgramValidationIssue: Equatable, Sendable {
    case emptyName
    case noExercises
    case emptyExerciseId(index: Int)
    case emptyExerciseName(index: Int)
    case invalidSetCount(index: Int, sets: Int)
    case invalidRepCount(index: Int, reps: Int)
    case invalidWeight(index: Int, weight: Double)
    case invalidRest(index: Int, seconds: Int)
    case duplicateExercise(exerciseId: String)

    public var message: String {
        switch self {
        case .emptyName:
            return "Give the program a name."
        case .noExercises:
            return "Add at least one exercise."
        case .emptyExerciseId(let index):
            return "Exercise \(index + 1) has no library match."
        case .emptyExerciseName(let index):
            return "Exercise \(index + 1) needs a name."
        case .invalidSetCount(let index, let sets):
            return "Exercise \(index + 1) has an invalid set count: \(sets)."
        case .invalidRepCount(let index, let reps):
            return "Exercise \(index + 1) has an invalid rep count: \(reps)."
        case .invalidWeight(let index, let weight):
            return "Exercise \(index + 1) has an invalid weight: \(weight)."
        case .invalidRest(let index, let seconds):
            return "Exercise \(index + 1) has invalid rest: \(seconds)s."
        case .duplicateExercise(let exerciseId):
            return "The program includes \(exerciseId) more than once."
        }
    }
}
