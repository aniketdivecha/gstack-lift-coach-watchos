import Testing

@Suite("WorkoutReadiness")
struct WorkoutReadinessTests {
    @Test("checking state cannot enter active set")
    func checkingCannotEnterActiveSet() {
        #expect(WorkoutReadiness.checking.canEnterActiveSet == false)
    }

    @Test("ready state can enter active set")
    func readyCanEnterActiveSet() {
        let readiness = WorkoutReadiness(
            healthKit: .ready("HR ready"),
            workoutSession: .ready("Workout active"),
            audio: .ready("Audio test spoken"),
            motion: .ready("Auto-count ready")
        )

        #expect(readiness.canEnterActiveSet == true)
        #expect(readiness.degradedHR == false)
        #expect(readiness.usesManualRepMode == false)
    }

    @Test("degraded HealthKit and motion can enter with fallbacks")
    func degradedCanEnterWithFallbacks() {
        let readiness = WorkoutReadiness(
            healthKit: .degraded("Timer-only rest"),
            workoutSession: .ready("Workout active"),
            audio: .ready("Audio test spoken"),
            motion: .degraded("Manual reps")
        )

        #expect(readiness.canEnterActiveSet == true)
        #expect(readiness.degradedHR == true)
        #expect(readiness.usesManualRepMode == true)
    }

    @Test("failed workout session blocks active set")
    func failedWorkoutBlocksActiveSet() {
        let readiness = WorkoutReadiness(
            healthKit: .ready("HR ready"),
            workoutSession: .failed("Workout failed"),
            audio: .ready("Audio test spoken"),
            motion: .ready("Auto-count ready")
        )

        #expect(readiness.canEnterActiveSet == false)
    }
}
