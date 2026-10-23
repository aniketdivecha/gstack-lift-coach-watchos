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
        rest: Int = 120
    ) -> ProgramExercise {
        ProgramExercise(
            exerciseId: exerciseId,
            name: name,
            targetSets: sets,
            targetReps: reps,
            targetWeight: weight,
            restSeconds: rest
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


    @Test("planned volume survives an absurd rep count")
    func plannedVolumeSurvivesAbsurdRepCount() {
        let exercise = makeExercise(sets: Int.max, reps: 2, weight: 1)

        #expect(exercise.plannedVolume == Double(Int.max) * 2)
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
}
