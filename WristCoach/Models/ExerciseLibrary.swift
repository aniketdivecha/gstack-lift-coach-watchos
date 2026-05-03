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
        let json = """
        {
          "groups": [
            {
              "id": "chest",
              "name": "Chest",
              "exercises": [
                {
                  "id": "bench_press",
                  "name": "Bench Press",
                  "muscleGroups": ["chest", "triceps"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 135.0
                },
                {
                  "id": "chest_fly",
                  "name": "Chest Fly",
                  "muscleGroups": ["chest"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "machine",
                  "minimumWeight": 5.0,
                  "defaultStartingWeight": 50.0
                },
                {
                  "id": "incline_press",
                  "name": "Incline Press",
                  "muscleGroups": ["chest", "shoulders"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 35.0
                },
                {
                  "id": "push_up",
                  "name": "Push Up",
                  "muscleGroups": ["chest", "triceps"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 0, "large": 0},
                  "isBodyweight": true,
                  "isIsometric": false,
                  "weightType": "bodyweight",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 0
                }
              ]
            },
            {
              "id": "back",
              "name": "Back",
              "exercises": [
                {
                  "id": "pull_up",
                  "name": "Pull Up",
                  "muscleGroups": ["back", "biceps"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 0, "large": 0},
                  "isBodyweight": true,
                  "isIsometric": false,
                  "weightType": "bodyweight",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 0
                },
                {
                  "id": "bent_over_row",
                  "name": "Bent Over Row",
                  "muscleGroups": ["back", "biceps"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 65.0
                }
              ]
            },
            {
              "id": "shoulders",
              "name": "Shoulders",
              "exercises": [
                {
                  "id": "overhead_press",
                  "name": "Overhead Press",
                  "muscleGroups": ["shoulders", "triceps"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 45.0
                },
                {
                  "id": "lateral_raise",
                  "name": "Lateral Raise",
                  "muscleGroups": ["shoulders"],
                  "defaultThreshold": 0.3,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 10.0
                }
              ]
            },
            {
              "id": "biceps",
              "name": "Biceps",
              "exercises": [
                {
                  "id": "bicep_curl",
                  "name": "Bicep Curl",
                  "muscleGroups": ["biceps"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 25.0
                },
                {
                  "id": "hammer_curl",
                  "name": "Hammer Curl",
                  "muscleGroups": ["biceps", "forearms"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 2.5,
                  "defaultStartingWeight": 25.0
                }
              ]
            },
            {
              "id": "triceps",
              "name": "Triceps",
              "exercises": [
                {
                  "id": "tricep_pushdown",
                  "name": "Tricep Pushdown",
                  "muscleGroups": ["triceps"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "cable",
                  "minimumWeight": 5.0,
                  "defaultStartingWeight": 40.0
                },
                {
                  "id": "skull_crusher",
                  "name": "Skull Crusher",
                  "muscleGroups": ["triceps"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 5.0,
                  "defaultStartingWeight": 40.0
                },
                {
                  "id": "dip",
                  "name": "Dip",
                  "muscleGroups": ["triceps", "chest"],
                  "defaultThreshold": 0.4,
                  "increment": {"small": 0, "large": 0},
                  "isBodyweight": true,
                  "isIsometric": false,
                  "weightType": "bodyweight",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 0
                }
              ]
            },
            {
              "id": "legs",
              "name": "Legs",
              "exercises": [
                {
                  "id": "squat",
                  "name": "Squat",
                  "muscleGroups": ["legs"],
                  "defaultThreshold": 0.5,
                  "increment": {"small": 5.0, "large": 10.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "free",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 95.0
                },
                {
                  "id": "leg_press",
                  "name": "Leg Press",
                  "muscleGroups": ["legs"],
                  "defaultThreshold": 0.5,
                  "increment": {"small": 5.0, "large": 10.0},
                  "isBodyweight": false,
                  "isIsometric": false,
                  "weightType": "machine",
                  "minimumWeight": 5.0,
                  "defaultStartingWeight": 150.0
                }
              ]
            },
            {
              "id": "core",
              "name": "Core",
              "exercises": [
                {
                  "id": "plank",
                  "name": "Plank",
                  "muscleGroups": ["core"],
                  "defaultThreshold": 0.3,
                  "increment": {"small": 0, "large": 0},
                  "isBodyweight": true,
                  "isIsometric": true,
                  "weightType": "bodyweight",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 0
                },
                {
                  "id": "crunch",
                  "name": "Crunch",
                  "muscleGroups": ["core"],
                  "defaultThreshold": 0.35,
                  "increment": {"small": 2.5, "large": 5.0},
                  "isBodyweight": true,
                  "isIsometric": false,
                  "weightType": "bodyweight",
                  "minimumWeight": 0,
                  "defaultStartingWeight": 0
                }
              ]
            }
          ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(ExerciseLibrary.self, from: data)
    }
}
