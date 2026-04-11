import Foundation

struct OverloadInput {
    let currentWeight: Double
    let lastSessionWeight: Double?
    let actualReps: Int
    let targetReps: Int
    let struggled: Bool
    let overCount: Bool
    let muscleGroup: String
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
        let increment = incrementFor(muscleGroup: input.muscleGroup)

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
            let newWeight = max(input.currentWeight - increment, minimumWeight(for: input.weightType))
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

    private static func incrementFor(muscleGroup: String) -> Double {
        // legs = 10 lb, chest/back = 5 lb, others = 2.5 lb
        switch muscleGroup {
        case "legs":
            return 10.0
        case "chest", "back":
            return 5.0
        default:
            return 2.5
        }
    }

    private static func minimumWeight(for weightType: Exercise.WeightType) -> Double {
        switch weightType {
        case .free: return 2.5
        case .machine, .cable: return 5.0
        case .bodyweight: return 0.0
        }
    }
}
