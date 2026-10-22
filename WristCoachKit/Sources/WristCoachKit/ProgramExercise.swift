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

    public var plannedVolume: Double {
        targetWeight * Double(targetSets * targetReps)
    }
}
