import Foundation

/// A saved workout. Drafts are allowed to be invalid, so callers validate
/// before sending one to the watch. Exercises are identified by `exerciseId`,
/// which must match an id in `WristCoach/Models/ExerciseLibrary.swift`.
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

    /// Checks that a program can be sent to the watch. This is deliberately
    /// strict: the watch rejects programs it cannot map to its exercise
    /// library, and it does not try to repair them.
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
            let exerciseId = exercise.exerciseId
            if exerciseId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.emptyExerciseId(index: index))
            } else if !Self.isLibraryStyleId(exerciseId) {
                // The watch does exact string matching, so "Bench Press" and
                // "Bench_Press" are not close enough to "bench_press".
                issues.append(.invalidExerciseId(index: index, exerciseId: exerciseId))
            } else if seenExerciseIds.contains(exerciseId) {
                issues.append(.duplicateExercise(exerciseId: exerciseId))
            } else {
                seenExerciseIds.insert(exerciseId)
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

    private static func isLibraryStyleId(_ id: String) -> Bool {
        guard !id.isEmpty else { return false }
        return id.allSatisfy { character in
            character.isASCII && (character.isLowercase || character.isNumber || character == "_")
        }
    }
}
