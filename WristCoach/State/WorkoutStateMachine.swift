import SwiftData
import Foundation
import HealthKit

@MainActor
class WorkoutStateMachine: ObservableObject {
    @Published var state: WorkoutState = .musclePicker(selected: WorkoutStateMachine.defaultSelectedGroups)

    private let modelContext: ModelContext
    private let exerciseLibrary = ExerciseLibrary.load()
    private let clock: Clock
    private let workoutSessionController: WorkoutSessionController
    private let speechAnnouncer: SpeechAnnouncer
    private var currentExercises: [Exercise] = []
    private var currentExerciseIndex: Int = 0
    private var currentReadiness: WorkoutReadiness = .checking
    private var readinessRequestID = UUID()
    private static let defaultSelectedGroups: Set<String> = ["chest", "tricep"]

    init(
        modelContext: ModelContext,
        clock: Clock = MonotonicClock(),
        workoutSessionController: WorkoutSessionController = HealthKitWorkoutSessionController(),
        speechAnnouncer: SpeechAnnouncer = AVSpeechSynthesizerAnnouncer()
    ) {
        self.modelContext = modelContext
        self.clock = clock
        self.workoutSessionController = workoutSessionController
        self.speechAnnouncer = speechAnnouncer
    }

    // MARK: - State Transitions

    func selectMuscleGroup(_ group: String) {
        var selected: Set<String> = []

        if case .musclePicker(let currentSelected) = state {
            selected = currentSelected
        } else if case .idle = state {
            selected = []
        } else {
            return
        }

        if selected.contains(group) {
            selected.remove(group)
        } else {
            selected.insert(group)
        }

        state = .musclePicker(selected: selected)
    }

    func startWorkout() {
        guard case .musclePicker(let selected) = state,
              selected.count >= 1 else {
            return
        }

        let exercises = generateExerciseQueue(for: selected)
        currentExercises = exercises
        currentExerciseIndex = 0
        state = .exerciseQueue(exercises: exercises, currentExerciseIndex: 0)
    }

    func beginExercise(exerciseIndex: Int) {
        guard case .exerciseQueue(let exercises, _) = state,
              exerciseIndex < exercises.count else {
            return
        }

        let exercise = exercises[exerciseIndex]
        currentExerciseIndex = exerciseIndex

        // Check if calibration needed
        let calibration = findCalibration(for: exercise.id)
        if calibration == nil && !exercise.isBodyweight {
            state = .calibration(exercises: exercises, currentExerciseIndex: exerciseIndex, exercise: exercise, currentWeight: exercise.defaultStartingWeight, attemptCount: 0)
            return
        }

        beginReadiness(exercises: exercises, exerciseIndex: exerciseIndex, exercise: exercise)
    }

    func beginWorkout(with exercises: [Exercise]) {
        guard case .exerciseQueue = state,
              exercises.isEmpty == false else {
            return
        }

        currentExercises = exercises
        currentExerciseIndex = 0
        beginExerciseFromQueue(exercises, exerciseIndex: 0)
    }

    func completeCalibration(exercise: Exercise, weight: Double, manualEntry: Bool) {
        guard case .calibration(let exercises, let exerciseIndex, _, _, _) = state else {
            return
        }

        let calibration = ExerciseCalibration(
            exerciseId: exercise.id,
            calibratedWeight: weight,
            detectionThreshold: exercise.defaultThreshold,
            manualEntry: manualEntry
        )
        modelContext.insert(calibration)
        beginReadiness(exercises: exercises, exerciseIndex: exerciseIndex, exercise: exercise)
    }

    func retryReadiness() {
        guard case .workoutReadiness(let exercises, let exerciseIndex, let exercise, _) = state else {
            return
        }

        beginReadiness(exercises: exercises, exerciseIndex: exerciseIndex, exercise: exercise)
    }

    func continueFromReadiness() {
        guard case .workoutReadiness(_, _, let exercise, let readiness) = state,
              readiness.canEnterActiveSet else {
            return
        }

        currentReadiness = readiness
        state = .activeSet(exercise: exercise, targetReps: 8, readiness: readiness)
    }

    func stopActiveSet(_ result: SetResult) {
        guard case .activeSet(let exercise, let targetReps, let readiness) = state else {
            return
        }

        let targetWeight = result.targetWeight ?? exercise.defaultStartingWeight
        let record = ExerciseRecord(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            targetWeight: targetWeight,
            targetReps: targetReps,
            actualReps: result.actualReps,
            repIntervals: result.repIntervals,
            struggled: result.struggled,
            manualOverride: result.manualOverride,
            degradedHR: readiness.degradedHR
        )
        modelContext.insert(record)

        let lastWeight = getLastWeight(for: exercise.id)
        let overload = ProgressiveOverload.compute(input: OverloadInput(
            currentWeight: targetWeight,
            lastSessionWeight: lastWeight,
            actualReps: result.actualReps,
            targetReps: targetReps,
            struggled: result.struggled,
            overCount: result.actualReps > targetReps,
            increment: exercise.increment.large,
            minimumWeight: exercise.minimumWeight,
            weightType: exercise.weightType
        ))

        state = .setComplete(
            exercises: currentExercises,
            currentExerciseIndex: currentExerciseIndex,
            exercise: exercise,
            result: result,
            overload: overload,
            targetReps: targetReps,
            readiness: readiness
        )
    }

    func continueToRest() {
        guard case .setComplete(let exercises, let exerciseIndex, let exercise, _, _, _, let readiness) = state else {
            return
        }

        currentExercises = exercises
        currentExerciseIndex = exerciseIndex
        state = .rest(
            exercises: exercises,
            currentExerciseIndex: exerciseIndex,
            exercise: exercise,
            startTime: Date(),
            targetHR: 115,
            degradedHR: readiness.degradedHR
        )
    }

    func finishRest() {
        guard case .rest(let exercises, let idx, let exercise, let startTime, _, _) = state else {
            return
        }

        let restDuration = Date().timeIntervalSince(startTime)
        let record = RestRecord(
            exerciseId: exercise.id,
            restDurationSeconds: restDuration,
            startHR: 0,
            endHR: 0,
            userOverrode: false
        )
        modelContext.insert(record)

        // Move to next exercise or summary
        if idx + 1 < exercises.count {
            currentExercises = exercises
            currentExerciseIndex = idx
            beginExerciseFromQueue(exercises, exerciseIndex: idx + 1)
        } else {
            let records = fetchRecords(for: exercises)
            state = .sessionSummary(exercises: exercises, records: records)
        }
    }

    func repeatExerciseAfterRest() {
        guard case .rest(let exercises, let idx, let exercise, let startTime, _, _) = state else {
            return
        }

        let restDuration = Date().timeIntervalSince(startTime)
        let record = RestRecord(
            exerciseId: exercise.id,
            restDurationSeconds: restDuration,
            startHR: 0,
            endHR: 0,
            userOverrode: false
        )
        modelContext.insert(record)

        currentExercises = exercises
        currentExerciseIndex = idx
        beginExerciseFromQueue(exercises, exerciseIndex: idx)
    }

    func skipRest() {
        guard case .rest(let exercises, let idx, let exercise, let startTime, _, _) = state else {
            return
        }

        let restDuration = Date().timeIntervalSince(startTime)
        let record = RestRecord(
            exerciseId: exercise.id,
            restDurationSeconds: restDuration,
            startHR: 0,
            endHR: 0,
            userOverrode: true
        )
        modelContext.insert(record)

        // Move to next exercise or summary
        if idx + 1 < exercises.count {
            currentExercises = exercises
            currentExerciseIndex = idx
            beginExerciseFromQueue(exercises, exerciseIndex: idx + 1)
        } else {
            let records = fetchRecords(for: exercises)
            state = .sessionSummary(exercises: exercises, records: records)
        }
    }

    func reset() {
        Task {
            await workoutSessionController.endWorkout()
        }
        currentExercises = []
        currentExerciseIndex = 0
        currentReadiness = .checking
        state = .musclePicker(selected: Self.defaultSelectedGroups)
    }

    func nextExercise(after exercise: Exercise) -> Exercise? {
        guard let index = currentExercises.firstIndex(where: { $0.id == exercise.id }),
              currentExercises.indices.contains(index + 1) else {
            return nil
        }
        return currentExercises[index + 1]
    }

    // MARK: - Helpers

    private func generateExerciseQueue(for selectedGroups: Set<String>) -> [Exercise] {
        var exercises: [Exercise] = []

        var seenExerciseIds: Set<String> = []

        for group in selectedGroups.sorted() {
            if let muscleGroup = exerciseLibrary.groups.first(where: { $0.id == group }) {
                for exercise in muscleGroup.exercises where !seenExerciseIds.contains(exercise.id) {
                    exercises.append(exercise)
                    seenExerciseIds.insert(exercise.id)
                }
            }
        }

        return exercises
    }

    private func beginReadiness(exercises: [Exercise], exerciseIndex: Int, exercise: Exercise) {
        currentExercises = exercises
        currentExerciseIndex = exerciseIndex
        let requestID = UUID()
        readinessRequestID = requestID
        let motionSource = CMMotionSource()
        let entryReadiness = WorkoutReadiness.optimisticEntry(motionAvailable: motionSource.isAvailable)
        currentReadiness = entryReadiness
        state = .activeSet(exercise: exercise, targetReps: 8, readiness: entryReadiness)

        Task {
            let readiness = await workoutSessionController.prepareForWorkout(
                speechAnnouncer: speechAnnouncer,
                motionSource: motionSource
            )
            guard readinessRequestID == requestID else { return }

            currentReadiness = readiness
            if case .activeSet(let activeExercise, let targetReps, _) = state,
               activeExercise.id == exercise.id {
                if readiness.canEnterActiveSet {
                    state = .activeSet(exercise: activeExercise, targetReps: targetReps, readiness: readiness)
                } else {
                    state = .workoutReadiness(
                        exercises: exercises,
                        currentExerciseIndex: exerciseIndex,
                        exercise: exercise,
                        readiness: readiness
                    )
                }
            }
        }
    }

    private func beginExerciseFromQueue(_ exercises: [Exercise], exerciseIndex: Int) {
        guard exerciseIndex < exercises.count else {
            return
        }

        let exercise = exercises[exerciseIndex]
        currentExerciseIndex = exerciseIndex

        let calibration = findCalibration(for: exercise.id)
        if calibration == nil && !exercise.isBodyweight {
            state = .calibration(
                exercises: exercises,
                currentExerciseIndex: exerciseIndex,
                exercise: exercise,
                currentWeight: exercise.defaultStartingWeight,
                attemptCount: 0
            )
            return
        }

        beginReadiness(exercises: exercises, exerciseIndex: exerciseIndex, exercise: exercise)
    }

    private func findCalibration(for exerciseId: String) -> ExerciseCalibration? {
        let fetchDescriptor = FetchDescriptor<ExerciseCalibration>(
            predicate: #Predicate<ExerciseCalibration> { $0.exerciseId == exerciseId }
        )
        do {
            return try modelContext.fetch(fetchDescriptor).first
        } catch {
            return nil
        }
    }

    private func getLastWeight(for exerciseId: String) -> Double? {
        let fetchDescriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate<ExerciseRecord> { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let records = try modelContext.fetch(fetchDescriptor)
            return records.first?.targetWeight
        } catch {
            return nil
        }
    }

    private func fetchRecords(for exercises: [Exercise]) -> [ExerciseRecord] {
        let exerciseIds = exercises.map { $0.id }
        let fetchDescriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate<ExerciseRecord> { exerciseIds.contains($0.exerciseId) },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

}
