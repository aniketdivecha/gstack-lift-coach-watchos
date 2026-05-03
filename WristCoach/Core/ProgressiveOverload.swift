import Foundation

struct OverloadInput {
    let currentWeight: Double
    let lastSessionWeight: Double?
    let actualReps: Int
    let targetReps: Int
    let struggled: Bool
    let overCount: Bool
    let increment: Double
    let minimumWeight: Double
    let weightType: Exercise.WeightType
}

struct OverloadResult {
    let newWeight: Double
    let message: String
    let celebrationLevel: CelebrationLevel
}

enum CelebrationLevel {
    case none
    case standard
    case gold
}

struct ProgressiveOverload {
    static func compute(input: OverloadInput) -> OverloadResult {
        if input.weightType == .bodyweight {
            return OverloadResult(
                newWeight: input.currentWeight,
                message: input.actualReps >= input.targetReps ? "Nice work." : "Good effort.",
                celebrationLevel: input.actualReps > input.targetReps ? .gold : .standard
            )
        }

        let increment = input.increment

        // ── CASE 1: hit target, struggled ──────────────────────────────
        if input.actualReps >= input.targetReps && input.struggled {
            return OverloadResult(
                newWeight: input.currentWeight,
                message: "Nice work.",
                celebrationLevel: .standard
            )
        }

        // ── CASE 2: hit target, no struggle ────────────────────────────
        if input.actualReps >= input.targetReps && !input.struggled && !input.overCount {
            return OverloadResult(
                newWeight: input.currentWeight + increment,
                message: "Solid set.",
                celebrationLevel: .standard
            )
        }

        // ── CASE 3: over-count, same weight as last session ────────────
        if input.overCount && (input.lastSessionWeight == nil || input.lastSessionWeight == input.currentWeight) {
            return OverloadResult(
                newWeight: input.currentWeight + increment,
                message: "You crushed it!",
                celebrationLevel: .gold
            )
        }

        // ── CASE 4: over-count, increased weight from last session ──────
        if input.overCount && input.lastSessionWeight != nil && input.lastSessionWeight! < input.currentWeight {
            return OverloadResult(
                newWeight: input.currentWeight + increment,
                message: "Exceptional lift!",
                celebrationLevel: .gold
            )
        }

        // ── CASE 5: under-count (didn't reach target) ──────────────────
        if input.actualReps < input.targetReps - 2 {
            let newWeight = max(input.currentWeight - increment, input.minimumWeight)
            return OverloadResult(
                newWeight: newWeight,
                message: "Good effort. Adjusting.",
                celebrationLevel: .none
            )
        }

        // ── Close miss (targetReps - 2 <= actualReps < targetReps) ─────
        return OverloadResult(
            newWeight: input.currentWeight,
            message: "Almost there.",
            celebrationLevel: .none
        )
    }

}
