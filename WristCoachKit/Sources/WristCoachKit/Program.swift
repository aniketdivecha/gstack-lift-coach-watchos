import Foundation

public struct Program: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var notes: String
    public var exercises: [ProgramExercise]
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        exercises: [ProgramExercise],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.exercises = exercises
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    public var plannedVolume: Double {
        exercises.reduce(0) { $0 + $1.plannedVolume }
    }

    public var validationIssues: [ProgramValidationIssue] {
        var issues: [ProgramValidationIssue] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyName)
        }

        if exercises.isEmpty {
            issues.append(.noExercises)
        }

        var seenExerciseIds: Set<String> = []
        for (index, exercise) in exercises.enumerated() {
            let trimmedId = exercise.exerciseId.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedId.isEmpty {
                issues.append(.emptyExerciseId(index: index))
            } else if seenExerciseIds.contains(trimmedId) {
                issues.append(.duplicateExercise(exerciseId: trimmedId))
            } else {
                seenExerciseIds.insert(trimmedId)
            }

            if exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.emptyExerciseName(index: index))
            }
            if exercise.targetSets < 1 {
                issues.append(.invalidSetCount(index: index, sets: exercise.targetSets))
            }
            if exercise.targetReps < 1 {
                issues.append(.invalidRepCount(index: index, reps: exercise.targetReps))
            }
            if exercise.targetWeight < 0 {
                issues.append(.invalidWeight(index: index, weight: exercise.targetWeight))
            }
            if exercise.restSeconds < 0 {
                issues.append(.invalidRest(index: index, seconds: exercise.restSeconds))
            }
        }

        return issues
    }

    public var isValid: Bool {
        validationIssues.isEmpty
    }
}
