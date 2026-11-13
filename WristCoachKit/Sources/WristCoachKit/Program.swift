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

    /// Returns a copy with `exercise` inserted at `index`.
    ///
    /// Out-of-range indexes append instead of trapping. Indices come from a
    /// UI, and a stale one should not take the editor down with it.
    public func adding(
        _ exercise: ProgramExercise,
        at index: Int? = nil,
        now: Date = .now
    ) -> Program {
        var copy = self
        let position = min(max(index ?? copy.exercises.count, 0), copy.exercises.count)
        copy.exercises.insert(exercise, at: position)
        copy.updatedAt = now
        return copy
    }

    /// Returns a copy with the exercise at `index` removed.
    ///
    /// An out-of-range index returns the program untouched, including
    /// `updatedAt`, so a no-op edit does not look like a save.
    public func removingExercise(at index: Int, now: Date = .now) -> Program {
        guard exercises.indices.contains(index) else { return self }

        var copy = self
        copy.exercises.remove(at: index)
        copy.updatedAt = now
        return copy
    }

    /// Returns a copy with one exercise moved to another position.
    ///
    /// `destination` is the index after the move, which is what a SwiftUI
    /// `onMove` handler gives once the offsets are resolved.
    public func movingExercise(
        from source: Int,
        to destination: Int,
        now: Date = .now
    ) -> Program {
        guard exercises.indices.contains(source),
              exercises.indices.contains(destination),
              source != destination
        else { return self }

        var copy = self
        let exercise = copy.exercises.remove(at: source)
        copy.exercises.insert(exercise, at: destination)
        copy.updatedAt = now
        return copy
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
