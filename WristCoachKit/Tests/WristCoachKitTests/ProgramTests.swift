import Foundation
import Testing
@testable import WristCoachKit

@Suite("Program")
struct ProgramTests {
    private func makeExercise(
        exerciseId: String = "bench_press",
        name: String = "Bench Press",
        sets: Int = 4,
        reps: Int = 8,
        weight: Double = 135,
        unit: WeightUnit = .pounds,
        rest: Int = 120
    ) -> ProgramExercise {
        ProgramExercise(
            exerciseId: exerciseId,
            name: name,
            targetSets: sets,
            targetReps: reps,
            targetWeight: weight,
            weightUnit: unit,
            restSeconds: rest
        )
    }

    private func makeProgram(
        exercises: [ProgramExercise]? = nil,
        updatedAt: Date = Date(timeIntervalSince1970: 1_000)
    ) -> Program {
        Program(
            name: "Push A",
            exercises: exercises ?? [makeExercise()],
            createdAt: Date(timeIntervalSince1970: 900),
            updatedAt: updatedAt
        )
    }

    @Test("a complete program has no validation issues")
    func validProgramHasNoIssues() {
        let program = Program(
            name: "Push A",
            exercises: [
                makeExercise(),
                makeExercise(exerciseId: "incline_press", name: "Incline Press", sets: 3, reps: 10, weight: 50, rest: 90)
            ]
        )

        #expect(program.validationIssues.isEmpty)
        #expect(program.isValid)
        #expect(program.totalSets == 7)
        #expect(program.plannedVolume == 5820)
    }

    @Test("an empty name is rejected")
    func emptyNameIsRejected() {
        let program = Program(name: "   ", exercises: [makeExercise()])

        #expect(program.validationIssues == [.emptyName])
        #expect(!program.isValid)
    }

    @Test("a program needs at least one exercise")
    func emptyProgramIsRejected() {
        let program = Program(name: "Push A", exercises: [])

        #expect(program.validationIssues == [.noExercises])
    }

    @Test("invalid targets are reported per exercise")
    func invalidTargetsAreReported() {
        let program = Program(
            name: "Push A",
            exercises: [
                makeExercise(sets: 0, reps: 0, weight: -5, rest: -1)
            ]
        )

        let issues = program.validationIssues
        #expect(issues.contains(.invalidSetCount(index: 0, sets: 0)))
        #expect(issues.contains(.invalidRepCount(index: 0, reps: 0)))
        #expect(issues.contains(.invalidWeight(index: 0, weight: -5)))
        #expect(issues.contains(.invalidRest(index: 0, seconds: -1)))
    }

    @Test("a repeated exercise is flagged")
    func duplicateExerciseIsFlagged() {
        let program = Program(
            name: "Push A",
            exercises: [
                makeExercise(),
                makeExercise(sets: 3, reps: 10, weight: 115)
            ]
        )

        #expect(program.validationIssues.contains(.duplicateExercise(exerciseId: "bench_press")))
    }

    @Test("missing library ids and names are flagged")
    func missingIdentityIsFlagged() {
        let program = Program(
            name: "Push A",
            exercises: [
                makeExercise(exerciseId: "  ", name: "  ")
            ]
        )

        let issues = program.validationIssues
        #expect(issues.contains(.emptyExerciseId(index: 0)))
        #expect(issues.contains(.emptyExerciseName(index: 0)))
    }

    @Test("planned volume multiplies weight, reps, and sets")
    func plannedVolumeMath() {
        let exercise = makeExercise(sets: 3, reps: 10, weight: 50)

        #expect(exercise.plannedVolume == 1500)
    }


    @Test("exercise ids must match the watch library format")
    func exerciseIdsMustMatchLibraryFormat() {
        let invalidIds = ["Bench Press", "Bench_Press", "bench-press", " bench_press", "bench press"]

        for id in invalidIds {
            let program = Program(name: "Push A", exercises: [makeExercise(exerciseId: id)])
            #expect(
                program.validationIssues.contains(.invalidExerciseId(index: 0, exerciseId: id)),
                "\(id) should be rejected"
            )
        }
    }

    @Test("planned volume survives an absurd rep count")
    func plannedVolumeSurvivesAbsurdRepCount() {
        let exercise = makeExercise(sets: Int.max, reps: 2, weight: 1)

        #expect(exercise.plannedVolume == Double(Int.max) * 2)
    }

    @Test("planned volume converts kilograms to pounds")
    func plannedVolumeConvertsKilograms() {
        let program = makeProgram(exercises: [
            makeExercise(exerciseId: "squats", name: "Squats", sets: 3, reps: 10, weight: 100, unit: .kilograms)
        ])

        #expect(abs(program.plannedVolume - 6_613.867_865_546_34) < 0.001)
    }

    @Test("planned volume sums mixed units in pounds")
    func plannedVolumeSumsMixedUnits() {
        let program = makeProgram(exercises: [
            makeExercise(),
            makeExercise(exerciseId: "squats", name: "Squats", sets: 3, reps: 10, weight: 50, unit: .kilograms)
        ])

        #expect(abs(program.plannedVolume - 7_626.933_932_773_17) < 0.001)
    }

    @Test("programs round trip through JSON")
    func codableRoundTrip() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let program = Program(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            name: "Push A",
            notes: "Chest and triceps",
            exercises: [makeExercise()],
            createdAt: created,
            updatedAt: created
        )

        let data = try JSONEncoder().encode(program)
        let decoded = try JSONDecoder().decode(Program.self, from: data)

        #expect(decoded == program)
    }

    @Test("adding an exercise appends it and stamps the edit")
    func addingAppends() {
        let now = Date(timeIntervalSince1970: 2_000)
        let program = makeProgram()
        let added = makeExercise(exerciseId: "incline_press", name: "Incline Press", sets: 3, reps: 10, weight: 50)

        let edited = program.adding(added, now: now)

        #expect(edited.exercises.map(\.exerciseId) == ["bench_press", "incline_press"])
        #expect(edited.updatedAt == now)
        #expect(program.exercises.count == 1)
    }

    @Test("adding at an index inserts instead of appending")
    func addingAtAnIndexInserts() {
        let second = makeExercise(exerciseId: "incline_press", name: "Incline Press", sets: 3, reps: 10, weight: 50)
        let program = makeProgram(exercises: [makeExercise(), second])
        let first = makeExercise(exerciseId: "chest_fly", name: "Chest Fly", sets: 3, reps: 12, weight: 80)

        let edited = program.adding(first, at: 0)

        #expect(edited.exercises.map(\.exerciseId) == ["chest_fly", "bench_press", "incline_press"])
    }

    @Test("adding past the end appends instead of trapping")
    func addingPastTheEndAppends() {
        let program = makeProgram()
        let added = makeExercise(exerciseId: "chest_fly", name: "Chest Fly", sets: 3, reps: 12, weight: 80)

        let edited = program.adding(added, at: 99)

        #expect(edited.exercises.map(\.exerciseId) == ["bench_press", "chest_fly"])
    }

    @Test("removing an exercise keeps the rest in order")
    func removingKeepsOrder() {
        let now = Date(timeIntervalSince1970: 2_000)
        let second = makeExercise(exerciseId: "incline_press", name: "Incline Press", sets: 3, reps: 10, weight: 50)
        let program = makeProgram(exercises: [makeExercise(), second])

        let edited = program.removingExercise(at: 0, now: now)

        #expect(edited.exercises.map(\.exerciseId) == ["incline_press"])
        #expect(edited.updatedAt == now)
    }

    @Test("removing an invalid index is a no-op")
    func removingInvalidIndexDoesNothing() {
        let originalUpdatedAt = Date(timeIntervalSince1970: 1_000)
        let program = makeProgram(updatedAt: originalUpdatedAt)

        let edited = program.removingExercise(at: 4, now: Date(timeIntervalSince1970: 2_000))

        #expect(edited == program)
        #expect(edited.updatedAt == originalUpdatedAt)
    }

    @Test("moving an exercise reorders the list")
    func movingReorders() {
        let now = Date(timeIntervalSince1970: 2_000)
        let second = makeExercise(exerciseId: "incline_press", name: "Incline Press", sets: 3, reps: 10, weight: 50)
        let third = makeExercise(exerciseId: "chest_fly", name: "Chest Fly", sets: 3, reps: 12, weight: 80)
        let program = makeProgram(exercises: [makeExercise(), second, third])

        let edited = program.movingExercise(from: 2, to: 0, now: now)

        #expect(edited.exercises.map(\.exerciseId) == ["chest_fly", "bench_press", "incline_press"])
        #expect(edited.updatedAt == now)
    }

    @Test("moving an invalid index is a no-op")
    func movingInvalidIndexDoesNothing() {
        let program = makeProgram()

        #expect(program.movingExercise(from: 0, to: 9) == program)
        #expect(program.movingExercise(from: 9, to: 0) == program)
        #expect(program.movingExercise(from: 0, to: 0) == program)
    }
}
