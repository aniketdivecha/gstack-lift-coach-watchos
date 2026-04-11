import SwiftData
import Foundation

class WorkoutStateMachine: ObservableObject {
    @Published var state: WorkoutState = .idle

    private let modelContext: ModelContext
    private let exerciseLibrary = ExerciseLibrary.load()
    private let clock: Clock
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKWorkoutBuilder?

    init(modelContext: ModelContext, clock: Clock = MonotonicClock()) {
        self.modelContext = modelContext
        self.clock = clock
    }

    // MARK: - State Transitions

    func selectMuscleGroup(_ group: String) {
        guard case .idle = state else { return }

        var selected: Set<String> = []
        if case .idle = state {
            // Start fresh
        } else if case .musclePicker(let currentSelected) = state {
            selected = currentSelected
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
        state = .exerciseQueue(exercises: exercises, currentExerciseIndex: 0)
    }

    func beginExercise(exerciseIndex: Int) {
        guard case .exerciseQueue(var exercises, var currentIndex) = state,
              exerciseIndex < exercises.count else {
            return
        }

        currentIndex = exerciseIndex
        let exercise = exercises[exerciseIndex]

        // Check if calibration needed
        let calibration = findCalibration(for: exercise.id)
        if calibration == nil && !exercise.isBodyweight {
            state = .calibration(exercise: exercise, currentWeight: exercise.defaultStartingWeight, attemptCount: 0)
            return
        }

        // Start workout session
        startWorkoutSession()

        let targetReps = 8 // Fixed for v1
        let threshold = calibration?.detectionThreshold ?? exercise.defaultThreshold
        let detector = RepDetector(threshold: threshold)

        state = .activeSet(exercise: exercise, targetReps: targetReps, repDetector: detector)
    }

    func startActiveSet() {
        guard case .activeSet(let exercise, let targetReps, var repDetector) = state else {
            return
        }

        // Signal start
        repDetector.reset()
        state = .activeSet(exercise: exercise, targetReps: targetReps, repDetector: repDetector)
    }

    func stopActiveSet() {
        guard case .activeSet(let exercise, let targetReps, let repDetector) = state else {
            return
        }

        let actualReps = repDetector.repCount
        let repIntervals = repDetector.repIntervals
        let struggled = repDetector.lastTwoFatigued.0 && repDetector.lastTwoFatigued.1

        // Save exercise record
        let record = ExerciseRecord(
            exerciseId: exercise.id,
            targetWeight: exercise.defaultStartingWeight,
            targetReps: targetReps,
            actualReps: actualReps,
            repIntervals: repIntervals,
            struggled: struggled
        )
        modelContext.insert(record)

        // Calculate new weight
        let lastWeight = getLastWeight(for: exercise.id)
        let overloadResult = ProgressiveOverload.compute(input: OverloadInput(
            currentWeight: exercise.defaultStartingWeight,
            lastSessionWeight: lastWeight,
            actualReps: actualReps,
            targetReps: targetReps,
            struggled: struggled,
            overCount: actualReps > targetReps,
            muscleGroup: exercise.muscleGroups.first ?? "",
            weightType: exercise.weightType
        ))

        // Move to rest
        state = .rest(exercise: exercise, startTime: Date(), targetHR: 115)
    }

    func finishRest() {
        guard case .rest(let exercise, let startTime, _) = state else {
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
        guard case .exerciseQueue(let exercises, let currentIndex) = state,
              currentIndex + 1 < exercises.count else {
            let records = fetchRecords(for: exercises)
            state = .sessionSummary(exercises: exercises, records: records)
            return
        }

        beginExercise(exerciseIndex: currentIndex + 1)
    }

    func skipRest() {
        guard case .rest(let exercise, let startTime, _) = state else {
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
        guard case .exerciseQueue(let exercises, let currentIndex) = state,
              currentIndex + 1 < exercises.count else {
            let records = fetchRecords(for: exercises)
            state = .sessionSummary(exercises: exercises, records: records)
            return
        }

        beginExercise(exerciseIndex: currentIndex + 1)
    }

    // MARK: - Helpers

    private func generateExerciseQueue(for selectedGroups: Set<String>) -> [Exercise] {
        var exercises: [Exercise] = []

        for group in selectedGroups {
            if let muscleGroup = exerciseLibrary.groups.first(where: { $0.id == group }) {
                // Pick most recent exercise or first in list
                let exercise = muscleGroup.exercises.first ?? ExerciseLibrary.load().groups.first(where: { $0.id == group })?.exercises.first ?? Exercise(id: "", name: "", muscleGroups: [], defaultThreshold: 0, increment: Exercise.Increments(small: 0, large: 0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 0, defaultStartingWeight: 0)
                exercises.append(exercise)
            }
        }

        // Cap at 5 exercises
        if exercises.count > 5 {
            exercises.removeLast(exercises.count - 5)
        }

        return exercises
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

    private func startWorkoutSession() {
        // HKWorkoutSession lifecycle handled by WatchKit app delegate
    }
}
