import Foundation

/// Starter programs that ship with the app. Exercise ids match
/// `WristCoach/Models/ExerciseLibrary.swift`, so a program can be sent to the
/// watch without a lookup table.
public enum SamplePrograms {
    public static let pushA = Program(
        id: uuid("A1000000-0000-4000-8000-000000000001"),
        name: "Push A",
        notes: "Chest and triceps",
        exercises: [
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000001"),
                exerciseId: "bench_press",
                name: "Bench Press",
                targetSets: 4,
                targetReps: 8,
                targetWeight: 135,
                restSeconds: 120
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000002"),
                exerciseId: "incline_press",
                name: "Incline Press",
                targetSets: 3,
                targetReps: 10,
                targetWeight: 50,
                restSeconds: 90
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000003"),
                exerciseId: "chest_fly",
                name: "Chest Fly",
                targetSets: 3,
                targetReps: 12,
                targetWeight: 80,
                restSeconds: 60
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000004"),
                exerciseId: "tricep_cable_pushdown",
                name: "Tricep Cable Pushdown",
                targetSets: 3,
                targetReps: 12,
                targetWeight: 40,
                restSeconds: 60
            )
        ],
        createdAt: referenceDate,
        updatedAt: referenceDate
    )

    public static let pullA = Program(
        id: uuid("A1000000-0000-4000-8000-000000000002"),
        name: "Pull A",
        notes: "Back and biceps",
        exercises: [
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000011"),
                exerciseId: "barbell_row",
                name: "Barbell Row",
                targetSets: 4,
                targetReps: 8,
                targetWeight: 95,
                restSeconds: 120
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000012"),
                exerciseId: "wide_grip_pull",
                name: "Wide Grip Pull",
                targetSets: 3,
                targetReps: 10,
                targetWeight: 100,
                restSeconds: 90
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000013"),
                exerciseId: "db_row",
                name: "DB Row",
                targetSets: 3,
                targetReps: 10,
                targetWeight: 40,
                restSeconds: 90
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000014"),
                exerciseId: "bicep_curl",
                name: "Bicep Curl",
                targetSets: 3,
                targetReps: 12,
                targetWeight: 30,
                restSeconds: 60
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000015"),
                exerciseId: "hammer_curl",
                name: "Hammer Curl",
                targetSets: 3,
                targetReps: 12,
                targetWeight: 25,
                restSeconds: 60
            )
        ],
        createdAt: referenceDate,
        updatedAt: referenceDate
    )

    public static let legs = Program(
        id: uuid("A1000000-0000-4000-8000-000000000003"),
        name: "Legs",
        notes: "Quads, hamstrings, and calves",
        exercises: [
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000021"),
                exerciseId: "squats",
                name: "Squats",
                targetSets: 4,
                targetReps: 8,
                targetWeight: 135,
                restSeconds: 150
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000022"),
                exerciseId: "deadlift",
                name: "Deadlift",
                targetSets: 3,
                targetReps: 5,
                targetWeight: 185,
                restSeconds: 180
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000023"),
                exerciseId: "lunges",
                name: "Lunges",
                targetSets: 3,
                targetReps: 10,
                targetWeight: 20,
                restSeconds: 90
            ),
            ProgramExercise(
                id: uuid("B1000000-0000-4000-8000-000000000024"),
                exerciseId: "calf_extension",
                name: "Calf extension",
                targetSets: 3,
                targetReps: 15,
                targetWeight: 70,
                restSeconds: 60
            )
        ],
        createdAt: referenceDate,
        updatedAt: referenceDate
    )

    public static var all: [Program] {
        [pushA, pullA, legs]
    }

    private static let referenceDate = Date(timeIntervalSince1970: 1_760_000_000)

    private static func uuid(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            preconditionFailure("Invalid sample UUID: \(value)")
        }
        return uuid
    }
}
