import SwiftData
import Testing

@MainActor
@Suite("WorkoutStateMachine")
struct WorkoutStateMachineTests {
    @Test("completed calibration opens selected exercise directly")
    func completedCalibrationOpensActiveSet() throws {
        let stateMachine = try makeStateMachine()

        stateMachine.startWorkout()
        stateMachine.beginExercise(exerciseIndex: 0)

        guard case .calibration(_, _, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected Bench Press calibration before the first weighted set")
            return
        }

        stateMachine.completeCalibration(exercise: exercise, weight: 135, manualEntry: false)

        guard case .activeSet(let activeExercise, let targetReps, let readiness) = stateMachine.state else {
            Issue.record("Expected selected exercise to open the GO screen immediately")
            return
        }

        #expect(activeExercise.name == "Bench Press")
        #expect(targetReps == 8)
        #expect(readiness.canEnterActiveSet == true)
    }

    @Test("every library exercise reaches set complete through its expected entry path")
    func everyLibraryExerciseCompletesExpectedFlow() throws {
        for group in ExerciseLibrary.load().groups {
            for exerciseIndex in group.exercises.indices {
                let expectedExercise = group.exercises[exerciseIndex]
                let stateMachine = try makeStateMachine(selectedGroup: group.id)

                stateMachine.startWorkout()
                guard case .exerciseQueue(let exercises, _) = stateMachine.state,
                      exercises.indices.contains(exerciseIndex) else {
                    Issue.record("Expected \(group.name) queue to contain \(expectedExercise.name)")
                    continue
                }

                #expect(exercises[exerciseIndex].id == expectedExercise.id)
                stateMachine.beginExercise(exerciseIndex: exerciseIndex)

                if expectedExercise.isBodyweight {
                    assertActiveSet(stateMachine, exercise: expectedExercise)
                } else {
                    guard case .calibration(_, _, let calibrationExercise, _, _) = stateMachine.state else {
                        Issue.record("Expected \(expectedExercise.name) to show calibration before GO")
                        continue
                    }
                    #expect(calibrationExercise.id == expectedExercise.id)
                    stateMachine.completeCalibration(
                        exercise: calibrationExercise,
                        weight: calibrationExercise.defaultStartingWeight,
                        manualEntry: false
                    )
                    assertActiveSet(stateMachine, exercise: expectedExercise)
                }

                stateMachine.stopActiveSet(SetResult(
                    actualReps: 8,
                    repIntervals: [],
                    struggled: false,
                    manualOverride: false
                ))

                guard case .setComplete(_, _, let completedExercise, let result, _, let targetReps, _) = stateMachine.state else {
                    Issue.record("Expected \(expectedExercise.name) to reach set complete")
                    continue
                }
                #expect(completedExercise.id == expectedExercise.id)
                #expect(result.actualReps == 8)
                #expect(targetReps == 8)

                stateMachine.continueToRest()
                guard case .rest(_, _, let restingExercise, _, _, _) = stateMachine.state else {
                    Issue.record("Expected \(expectedExercise.name) to continue to rest")
                    continue
                }
                #expect(restingExercise.id == expectedExercise.id)
            }
        }
    }

    private func makeStateMachine(selectedGroup: String? = nil) throws -> WorkoutStateMachine {
        let container = try ModelContainer(
            for: ExerciseRecord.self,
            RestRecord.self,
            ExerciseCalibration.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let stateMachine = WorkoutStateMachine(
            modelContext: ModelContext(container),
            workoutSessionController: ImmediateWorkoutSessionController(),
            speechAnnouncer: SilentSpeechAnnouncer()
        )

        if let selectedGroup {
            selectOnly(selectedGroup, in: stateMachine)
        }

        return stateMachine
    }

    private func selectOnly(_ group: String, in stateMachine: WorkoutStateMachine) {
        guard case .musclePicker(let selectedGroups) = stateMachine.state else { return }

        for selectedGroup in selectedGroups where selectedGroup != group {
            stateMachine.selectMuscleGroup(selectedGroup)
        }

        if !selectedGroups.contains(group) {
            stateMachine.selectMuscleGroup(group)
        }
    }

    private func assertActiveSet(_ stateMachine: WorkoutStateMachine, exercise: Exercise) {
        guard case .activeSet(let activeExercise, let targetReps, let readiness) = stateMachine.state else {
            Issue.record("Expected \(exercise.name) to open the GO screen")
            return
        }

        #expect(activeExercise.id == exercise.id)
        #expect(targetReps == 8)
        #expect(readiness.canEnterActiveSet == true)
    }
}

private final class ImmediateWorkoutSessionController: WorkoutSessionController {
    func prepareForWorkout(
        speechAnnouncer: SpeechAnnouncer,
        motionSource: MotionSource
    ) async -> WorkoutReadiness {
        WorkoutReadiness(
            healthKit: .ready("HR ready"),
            workoutSession: .ready("Workout active"),
            audio: .ready("Audio ready"),
            motion: .ready("Auto-count ready")
        )
    }

    func endWorkout() async {}
}

private final class SilentSpeechAnnouncer: SpeechAnnouncer {
    func say(_ text: String) {}
    func prewarm() {}
}
