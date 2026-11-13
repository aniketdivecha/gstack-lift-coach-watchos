import Foundation

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case pounds
    case kilograms

    public var abbreviation: String {
        switch self {
        case .pounds: return "lb"
        case .kilograms: return "kg"
        }
    }

    /// Pounds in one unit of this weight.
    public var poundsPerUnit: Double {
        switch self {
        case .pounds: return 1
        case .kilograms: return Self.poundsPerKilogram
        }
    }

    public static let poundsPerKilogram = 2.204_622_621_848_78
}

public struct ProgramExercise: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var exerciseId: String
    public var name: String
    public var targetSets: Int
    public var targetReps: Int
    public var targetWeight: Double
    public var weightUnit: WeightUnit
    public var restSeconds: Int

    public init(
        id: UUID = UUID(),
        exerciseId: String,
        name: String,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double,
        weightUnit: WeightUnit = .pounds,
        restSeconds: Int = 90
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.weightUnit = weightUnit
        self.restSeconds = restSeconds
    }

    /// Total weight moved if every planned set is completed, in this
    /// exercise's own unit.
    ///
    /// Convert before multiplying. Sets times reps can overflow `Int` for
    /// optimistic drafts, and crashing is a bad way to report a typo.
    public var plannedVolume: Double {
        targetWeight * Double(targetSets) * Double(targetReps)
    }

    /// The same volume in pounds, so exercises with different units can be
    /// added together.
    public var plannedVolumeInPounds: Double {
        plannedVolume * weightUnit.poundsPerUnit
    }
}
