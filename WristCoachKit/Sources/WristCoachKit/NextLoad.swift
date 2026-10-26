import Foundation

public struct SetOutcome: Equatable, Sendable {
    public let actualReps: Int
    public let struggled: Bool

    public init(actualReps: Int, struggled: Bool = false) {
        self.actualReps = actualReps
        self.struggled = struggled
    }
}

public enum NextLoadReason: Equatable, Sendable {
    case increase
    case hold
    case decrease
}

public struct NextLoadSuggestion: Equatable, Sendable {
    public let weight: Double
    public let reason: NextLoadReason

    public init(weight: Double, reason: NextLoadReason) {
        self.weight = weight
        self.reason = reason
    }
}

/// The weight to put on the bar next time.
///
/// These rules mirror the watch's `ProgressiveOverload` for now. When the
/// watch adopts `WristCoachKit`, this becomes the only copy.
public enum NextLoad {
    public static func suggest(
        for exercise: ProgramExercise,
        outcome: SetOutcome,
        increment: Double,
        minimumWeight: Double
    ) -> NextLoadSuggestion {
        let current = max(exercise.targetWeight, 0)
        let step = max(increment, 0)
        // Never suggest loading below the floor, and never suggest a decrease
        // that lands above the current weight.
        let floor = min(max(minimumWeight, 0), current)
        let reps = max(outcome.actualReps, 0)

        if reps >= exercise.targetReps {
            if outcome.struggled || step == 0 {
                return NextLoadSuggestion(weight: current, reason: .hold)
            }
            return NextLoadSuggestion(weight: current + step, reason: .increase)
        }

        // Missing by one rep is noise. Missing by more than two means the
        // weight was wrong, not the effort.
        if reps < exercise.targetReps - 2 {
            let reduced = max(current - step, floor)
            return NextLoadSuggestion(
                weight: reduced,
                reason: reduced < current ? .decrease : .hold
            )
        }

        return NextLoadSuggestion(weight: current, reason: .hold)
    }
}
