import Foundation
import Testing
@testable import WristCoachKit

@Suite("NextLoad")
struct NextLoadTests {
    private func exercise(weight: Double = 135, reps: Int = 8) -> ProgramExercise {
        ProgramExercise(
            exerciseId: "bench_press",
            name: "Bench Press",
            targetSets: 4,
            targetReps: reps,
            targetWeight: weight,
            restSeconds: 120
        )
    }

    @Test("a clean set adds one increment")
    func cleanSetAddsWeight() {
        let suggestion = NextLoad.suggest(
            for: exercise(),
            outcome: SetOutcome(actualReps: 8),
            increment: 5,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 140, reason: .increase))
    }

    @Test("an over-counted clean set also adds weight")
    func overCountAddsWeight() {
        let suggestion = NextLoad.suggest(
            for: exercise(),
            outcome: SetOutcome(actualReps: 10),
            increment: 5,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 140, reason: .increase))
    }

    @Test("a grind keeps the weight")
    func grindKeepsWeight() {
        let suggestion = NextLoad.suggest(
            for: exercise(),
            outcome: SetOutcome(actualReps: 8, struggled: true),
            increment: 5,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 135, reason: .hold))
    }

    @Test("missing by one or two reps keeps the weight")
    func closeMissKeepsWeight() {
        for reps in [6, 7] {
            let suggestion = NextLoad.suggest(
                for: exercise(),
                outcome: SetOutcome(actualReps: reps),
                increment: 5,
                minimumWeight: 45
            )

            #expect(suggestion == NextLoadSuggestion(weight: 135, reason: .hold))
        }
    }

    @Test("missing by more than two reps removes one increment")
    func bigMissRemovesWeight() {
        let suggestion = NextLoad.suggest(
            for: exercise(),
            outcome: SetOutcome(actualReps: 5),
            increment: 5,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 130, reason: .decrease))
    }

    @Test("a decrease stops at the minimum weight")
    func decreaseStopsAtMinimum() {
        let suggestion = NextLoad.suggest(
            for: exercise(weight: 135),
            outcome: SetOutcome(actualReps: 2),
            increment: 10,
            minimumWeight: 130
        )

        #expect(suggestion == NextLoadSuggestion(weight: 130, reason: .decrease))
    }

    @Test("a zero increment holds the weight")
    func zeroIncrementHolds() {
        let suggestion = NextLoad.suggest(
            for: exercise(),
            outcome: SetOutcome(actualReps: 8),
            increment: 0,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 135, reason: .hold))
    }

    @Test("a minimum above the current weight does not raise it")
    func minimumAboveCurrentDoesNotRaise() {
        let suggestion = NextLoad.suggest(
            for: exercise(weight: 20),
            outcome: SetOutcome(actualReps: 0),
            increment: 5,
            minimumWeight: 45
        )

        #expect(suggestion == NextLoadSuggestion(weight: 20, reason: .hold))
    }
}
