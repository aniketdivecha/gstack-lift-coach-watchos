import Foundation

struct Exercise: Codable, Identifiable {
    let id: String
    let name: String
    let muscleGroups: [String]
    let defaultThreshold: Double
    let increment: Increments
    let isBodyweight: Bool
    let isIsometric: Bool
    let weightType: WeightType
    let minimumWeight: Double
    let defaultStartingWeight: Double

    enum WeightType: String, Codable {
        case free
        case machine
        case cable
        case bodyweight
    }

    struct Increments: Codable {
        let small: Double
        let large: Double
    }
}

struct MuscleGroup: Codable, Identifiable {
    let id: String
    let name: String
    let exercises: [Exercise]
}

struct ExerciseLibrary: Codable {
    let groups: [MuscleGroup]

    static func load() -> ExerciseLibrary {
        ExerciseLibrary(groups: [
            MuscleGroup(id: "chest", name: "Chest", exercises: [
                exercise("bench_press", "Bench Press", ["chest", "tricep"], 50, 10, .machine),
                exercise("incline_press", "Incline Press", ["chest", "tricep"], 40, 10, .free),
                exercise("chest_fly", "Chest Fly", ["chest", "tricep"], 80, 10, .machine),
                exercise("overhead_db_pullover", "Overhead DB Pullover", ["chest", "tricep"], 50, 10, .free)
            ]),
            MuscleGroup(id: "tricep", name: "Tricep", exercises: [
                exercise("skull_crusher", "Skull Crusher", ["tricep"], 40, 5, .free),
                exercise("tricep_cable_pushdown", "Tricep Cable Pushdown", ["tricep"], 40, 5, .cable),
                exercise("tricep_db_extension", "Tricep DB Extension", ["tricep"], 30, 5, .free)
            ]),
            MuscleGroup(id: "back", name: "Back", exercises: [
                exercise("cable_machine_row", "Cable / Machine Row", ["back", "biceps"], 110, 10, .machine),
                exercise("wide_grip_pull", "Wide Grip Pull", ["back", "biceps"], 100, 10, .machine),
                exercise("close_grip_pull", "Close grip pull", ["back", "biceps"], 110, 10, .machine),
                exercise("db_row", "DB Row", ["back", "biceps"], 40, 10, .free),
                exercise("hyper_extension", "Hyper Extension", ["back", "biceps"], 25, 10, .free),
                exercise("barbell_row", "Barbell Row", ["back", "biceps"], 50, 10, .free)
            ]),
            MuscleGroup(id: "legs", name: "Legs", exercises: [
                exercise("deadlift", "Deadlift", ["legs", "back"], 150, 25, .free),
                exercise("squats", "Squats", ["legs"], 70, 25, .free),
                exercise("quadraceps", "Quadraceps", ["legs"], 80, 25, .machine),
                exercise("lunges", "Lunges", ["legs"], 20, 25, .free),
                exercise("hamstrings", "Hamstrings", ["legs"], 90, 25, .machine),
                exercise("calf_extension", "Calf extension", ["legs"], 70, 25, .machine)
            ]),
            MuscleGroup(id: "biceps", name: "Biceps", exercises: [
                exercise("bicep_curl", "Bicep Curl", ["biceps"], 40, 5, .free),
                exercise("preacher_curl", "Preacher Curl", ["biceps"], 30, 5, .free),
                exercise("bicep_machine_curl", "Bicep Machine Curl", ["biceps"], 40, 5, .machine),
                exercise("hammer_curl", "Hammer Curl", ["biceps"], 40, 5, .free),
                exercise("bicep_extension", "Bicep Extension", ["biceps"], 50, 5, .cable)
            ]),
            MuscleGroup(id: "shoulders", name: "Shoulders", exercises: [
                exercise("shoulder_press", "Shoulder Press", ["shoulders"], 70, 5, .machine),
                exercise("front_extension", "Front Extension", ["shoulders"], 40, 5, .free),
                exercise("side_extension", "Side Extension", ["shoulders"], 80, 5, .machine),
                exercise("barbell_front_raise", "Barbell Front Raise", ["shoulders"], 60, 5, .free),
                exercise("traps_extension", "Traps Extension", ["shoulders"], 60, 5, .machine),
                exercise("rear_delt_fly", "Rear Delt Fly", ["shoulders"], 80, 5, .machine)
            ])
        ])
    }

    private static func exercise(
        _ id: String,
        _ name: String,
        _ muscleGroups: [String],
        _ startingWeight: Double,
        _ weightIncrement: Double,
        _ weightType: Exercise.WeightType
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroups: muscleGroups,
            defaultThreshold: 0.4,
            increment: Exercise.Increments(small: weightIncrement, large: weightIncrement),
            isBodyweight: false,
            isIsometric: false,
            weightType: weightType,
            minimumWeight: weightIncrement,
            defaultStartingWeight: startingWeight
        )
    }
}
