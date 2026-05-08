import Foundation
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

        guard case .activeSet(let activeExercise, let targetReps, let readiness, _, _) = stateMachine.state else {
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

    @Test("ready after rest advances to the next exercise")
    func readyAfterRestAdvancesToNextExercise() throws {
        let stateMachine = try makeStateMachine(selectedGroup: "chest")

        stateMachine.startWorkout()
        guard case .exerciseQueue(let exercises, _) = stateMachine.state,
              exercises.count >= 2 else {
            Issue.record("Expected chest queue to contain multiple exercises")
            return
        }

        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let firstExercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: firstExercise,
            weight: firstExercise.defaultStartingWeight,
            manualEntry: false
        )
        stateMachine.stopActiveSet(SetResult(actualReps: 8, repIntervals: [], struggled: false, manualOverride: false))
        stateMachine.continueToRest()
        stateMachine.finishRest()

        guard case .calibration(_, let exerciseIndex, let nextExercise, _, _) = stateMachine.state else {
            Issue.record("Expected Ready to advance from rest into the next exercise")
            return
        }

        #expect(exerciseIndex == 1)
        #expect(nextExercise.id == exercises[1].id)
    }

    @Test("repeat after rest starts the same exercise again")
    func repeatAfterRestStartsSameExercise() throws {
        let stateMachine = try makeStateMachine(selectedGroup: "chest")

        stateMachine.startWorkout()
        guard case .exerciseQueue(let exercises, _) = stateMachine.state,
              let firstExercise = exercises.first else {
            Issue.record("Expected chest queue to contain exercises")
            return
        }

        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let calibrationExercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: calibrationExercise,
            weight: calibrationExercise.defaultStartingWeight,
            manualEntry: false
        )
        stateMachine.stopActiveSet(SetResult(actualReps: 8, repIntervals: [], struggled: false, manualOverride: false))
        stateMachine.continueToRest()
        stateMachine.repeatExerciseAfterRest()

        guard case .activeSet(let repeatedExercise, let targetReps, _, _, _) = stateMachine.state else {
            Issue.record("Expected Repeat to return to the same active exercise")
            return
        }

        #expect(repeatedExercise.id == firstExercise.id)
        #expect(targetReps == 8)
    }

    @Test("active set uses adjusted weight for overload")
    func activeSetUsesAdjustedWeightForOverload() throws {
        let stateMachine = try makeStateMachine(selectedGroup: "chest")

        stateMachine.startWorkout()
        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: exercise,
            weight: exercise.defaultStartingWeight,
            manualEntry: false
        )
        stateMachine.stopActiveSet(SetResult(
            actualReps: 8,
            repIntervals: [],
            struggled: false,
            manualOverride: false,
            targetWeight: 60
        ))

        guard case .setComplete(_, _, _, _, let overload, _, _) = stateMachine.state else {
            Issue.record("Expected adjusted-weight set to complete")
            return
        }

        #expect(overload.newWeight == 70)
    }

    @Test("completed set logs exercise name weight repetitions and timestamp")
    func completedSetLogsExerciseDetails() throws {
        let (stateMachine, context) = try makeStateMachineWithContext(selectedGroup: "chest")

        stateMachine.startWorkout()
        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: exercise,
            weight: exercise.defaultStartingWeight,
            manualEntry: false
        )
        stateMachine.stopActiveSet(SetResult(
            actualReps: 9,
            repIntervals: [],
            struggled: false,
            manualOverride: false,
            targetWeight: 60
        ))

        let records = try context.fetch(FetchDescriptor<ExerciseRecord>())
        guard let record = records.first else {
            Issue.record("Expected completed set to create an exercise log row")
            return
        }

        #expect(record.exerciseName == "Bench Press")
        #expect(record.targetWeight == 60)
        #expect(record.actualReps == 9)
        #expect(record.date <= Date())
    }

    @Test("custom queue begins selected exercises in chosen order")
    func customQueueBeginsSelectedExercisesInChosenOrder() throws {
        let stateMachine = try makeStateMachine(selectedGroup: "chest")

        stateMachine.startWorkout()
        guard case .exerciseQueue(let exercises, _) = stateMachine.state,
              exercises.count >= 3 else {
            Issue.record("Expected chest queue to contain several exercises")
            return
        }

        let editedQueue = [exercises[2], exercises[0]]
        stateMachine.beginWorkout(with: editedQueue)

        guard case .calibration(let activeQueue, let exerciseIndex, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected edited queue to start calibration for first selected exercise")
            return
        }

        #expect(activeQueue.map(\.id) == editedQueue.map(\.id))
        #expect(exerciseIndex == 0)
        #expect(exercise.id == editedQueue[0].id)
    }

    @Test("recalibrate active exercise returns to calibration")
    func recalibrateActiveExerciseReturnsToCalibration() throws {
        let stateMachine = try makeStateMachine(selectedGroup: "chest")

        stateMachine.startWorkout()
        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: exercise,
            weight: exercise.defaultStartingWeight,
            manualEntry: false
        )
        stateMachine.recalibrateActiveExercise(currentWeight: 72)

        guard case .calibration(_, let exerciseIndex, let calibrationExercise, let currentWeight, _) = stateMachine.state else {
            Issue.record("Expected recalibration to reopen calibration")
            return
        }

        #expect(exerciseIndex == 0)
        #expect(calibrationExercise.id == exercise.id)
        #expect(currentWeight == 72)
    }

    @Test("recalibration replaces existing calibration")
    func recalibrationReplacesExistingCalibration() throws {
        let (stateMachine, context) = try makeStateMachineWithContext(selectedGroup: "chest")

        stateMachine.startWorkout()
        stateMachine.beginExercise(exerciseIndex: 0)
        guard case .calibration(_, _, let exercise, _, _) = stateMachine.state else {
            Issue.record("Expected first chest exercise to calibrate")
            return
        }

        stateMachine.completeCalibration(
            exercise: exercise,
            weight: 50,
            manualEntry: false
        )
        stateMachine.recalibrateActiveExercise(currentWeight: 70)
        stateMachine.completeCalibration(
            exercise: exercise,
            weight: 70,
            manualEntry: false
        )

        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<ExerciseCalibration>(
            predicate: #Predicate<ExerciseCalibration> { $0.exerciseId == exerciseId }
        )
        let calibrations = try context.fetch(descriptor)

        #expect(calibrations.count == 1)
        #expect(calibrations.first?.calibratedWeight == 70)
    }

    private func makeStateMachine(selectedGroup: String? = nil) throws -> WorkoutStateMachine {
        try makeStateMachineWithContext(selectedGroup: selectedGroup).stateMachine
    }

    private func makeStateMachineWithContext(selectedGroup: String? = nil) throws -> (stateMachine: WorkoutStateMachine, context: ModelContext) {
        let container = try ModelContainer(
            for: ExerciseRecord.self,
            RestRecord.self,
            ExerciseCalibration.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let stateMachine = WorkoutStateMachine(
            modelContext: context,
            workoutSessionController: ImmediateWorkoutSessionController(),
            speechAnnouncer: SilentSpeechAnnouncer()
        )

        if let selectedGroup {
            selectOnly(selectedGroup, in: stateMachine)
        }

        return (stateMachine, context)
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
        guard case .activeSet(let activeExercise, let targetReps, let readiness, _, _) = stateMachine.state else {
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
