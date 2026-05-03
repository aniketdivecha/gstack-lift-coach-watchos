import Testing

@Suite("ProgressiveOverload")
struct ProgressiveOverloadTests {
    @Test("bodyweight exercises never change load")
    func bodyweightNoOp() {
        let result = ProgressiveOverload.compute(input: OverloadInput(
            currentWeight: 0,
            lastSessionWeight: nil,
            actualReps: 12,
            targetReps: 8,
            struggled: false,
            overCount: true,
            increment: 100,
            minimumWeight: 100,
            weightType: .bodyweight
        ))

        #expect(result.newWeight == 0)
        #expect(result.celebrationLevel == .gold)
    }

    @Test("uses exercise-provided increment")
    func usesExerciseProvidedIncrement() {
        let result = ProgressiveOverload.compute(input: OverloadInput(
            currentWeight: 50,
            lastSessionWeight: 50,
            actualReps: 8,
            targetReps: 8,
            struggled: false,
            overCount: false,
            increment: 7.5,
            minimumWeight: 30,
            weightType: .free
        ))

        #expect(result.newWeight == 57.5)
    }

    @Test("uses exercise-provided minimum weight")
    func usesExerciseProvidedMinimumWeight() {
        let result = ProgressiveOverload.compute(input: OverloadInput(
            currentWeight: 32.5,
            lastSessionWeight: 40,
            actualReps: 3,
            targetReps: 8,
            struggled: true,
            overCount: false,
            increment: 7.5,
            minimumWeight: 30,
            weightType: .free
        ))

        #expect(result.newWeight == 30)
    }
}
