import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var stateMachine: WorkoutStateMachine

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ExerciseRecord.self, RestRecord.self, ExerciseCalibration.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        let context = ModelContext(container)
        _stateMachine = StateObject(wrappedValue: WorkoutStateMachine(modelContext: context))
    }

    var body: some View {
        Group {
            if let screen = ProcessInfo.processInfo.environment["WRISTCOACH_V5_SCREEN"] {
                V5ScreenshotScreen(screen: screen)
            } else {
                appBody
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    @ViewBuilder
    private var appBody: some View {
        switch stateMachine.state {
            case .idle:
                MusclePickerView(
                    selectedGroups: [],
                    onSelectGroup: { group in
                        stateMachine.selectMuscleGroup(group)
                    },
                    onStartWorkout: {
                        stateMachine.startWorkout()
                    }
                )

            case .musclePicker(let selected):
                MusclePickerView(
                    selectedGroups: selected,
                    onSelectGroup: { group in
                        stateMachine.selectMuscleGroup(group)
                    },
                    onStartWorkout: {
                        stateMachine.startWorkout()
                    }
                )

            case .exerciseQueue(let exercises, let currentIndex):
                ExerciseQueueView(
                    exercises: exercises,
                    onBegin: {
                        stateMachine.beginExercise(exerciseIndex: currentIndex)
                    },
                    onSelectExercise: { index in
                        stateMachine.beginExercise(exerciseIndex: index)
                    }
                )

            case .calibration( _, _, let exercise, let currentWeight, _):
                CalibrationView(
                    exercise: exercise,
                    onComplete: { weight in
                        stateMachine.completeCalibration(exercise: exercise, weight: weight, manualEntry: false)
                    },
                    onManualEntry: {
                        stateMachine.completeCalibration(exercise: exercise, weight: currentWeight, manualEntry: true)
                    }
                )

            case .workoutReadiness(_, _, let exercise, let readiness):
                WorkoutReadinessView(
                    exercise: exercise,
                    readiness: readiness,
                    onContinue: {
                        stateMachine.continueFromReadiness()
                    },
                    onRetry: {
                        stateMachine.retryReadiness()
                    }
                )

            case .activeSet(let exercise, let targetReps, let readiness):
                ActiveSetView(
                    exercise: exercise,
                    targetReps: targetReps,
                    manualMode: readiness.usesManualRepMode,
                    onStop: { result in
                        stateMachine.stopActiveSet(result)
                    }
                )

            case .setComplete(_, _, let exercise, let result, let overload, let targetReps, _):
                SetCompleteView(
                    exercise: exercise,
                    result: result,
                    overload: overload,
                    targetReps: targetReps,
                    onRest: {
                        stateMachine.continueToRest()
                    }
                )

            case .rest(_, _, let exercise, _, let targetHR, let degradedHR):
                RestView(
                    exercise: exercise,
                    nextExercise: stateMachine.nextExercise(after: exercise),
                    targetHR: targetHR,
                    degradedHR: degradedHR,
                    onRepeat: {
                        stateMachine.repeatExerciseAfterRest()
                    },
                    onNext: {
                        stateMachine.finishRest()
                    }
                )

            case .sessionSummary(let exercises, let records):
                SessionSummaryView(
                    exercises: exercises,
                    records: records,
                    onDone: {
                        stateMachine.reset()
                    }
                )
        }
    }
}

#Preview {
    ContentView()
}

struct V5ScreenshotScreen: View {
    let screen: String
    private var exercise: Exercise { Self.selectedExercise() }
    private var raisedExercise: Exercise {
        let increase = exercise.increment.large == 0 ? 0 : exercise.increment.large
        return exercise.withStartingWeight(exercise.defaultStartingWeight + increase)
    }

    var body: some View {
        Group {
            switch screen {
            case "picker":
                MusclePickerView(
                    selectedGroups: ["chest", "tricep"],
                    onSelectGroup: { _ in },
                    onStartWorkout: {}
                )
            case "queue":
                ExerciseQueueView(exercises: Self.queueExercises, onBegin: {}, onSelectExercise: { _ in })
            case "calibration":
                CalibrationView(exercise: exercise, currentWeight: exercise.defaultStartingWeight, onComplete: { _ in }, onManualEntry: {})
            case "preset":
                V5PresetScreen(exercise: exercise, weightRaised: false)
            case "active-preset":
                ActiveSetView(exercise: exercise, targetReps: 8, manualMode: false, onStop: { _ in })
            case "active-manual-over":
                ActiveSetView(
                    exercise: exercise,
                    targetReps: 8,
                    manualMode: true,
                    initialRepCount: 9,
                    initialCountingStarted: true,
                    onStop: { _ in }
                )
            case "counting":
                V5CountingScreen(exercise: exercise, reps: 6, targetReps: 8, weightRaised: false)
            case "complete":
                SetCompleteView(
                    exercise: exercise,
                    result: SetResult(actualReps: 8, repIntervals: [], struggled: true, manualOverride: false),
                    overload: OverloadResult(newWeight: exercise.defaultStartingWeight, message: "Nice work.", celebrationLevel: .standard),
                    targetReps: 8,
                    onRest: {}
                )
            case "over-count":
                V5CountingScreen(exercise: exercise, reps: 9, targetReps: 8, weightRaised: false)
            case "complete-over":
                SetCompleteView(
                    exercise: exercise,
                    result: SetResult(actualReps: 10, repIntervals: [], struggled: false, manualOverride: false),
                    overload: OverloadResult(newWeight: raisedExercise.defaultStartingWeight, message: "You crushed it!", celebrationLevel: .gold),
                    targetReps: 8,
                    onRest: {}
                )
            case "preset-up":
                V5PresetScreen(exercise: raisedExercise, weightRaised: exercise.increment.large > 0)
            case "counting-up":
                V5CountingScreen(exercise: raisedExercise, reps: 10, targetReps: 8, weightRaised: exercise.increment.large > 0)
            case "complete-up":
                SetCompleteView(
                    exercise: raisedExercise,
                    result: SetResult(actualReps: 10, repIntervals: [], struggled: false, manualOverride: false),
                    overload: OverloadResult(newWeight: raisedExercise.defaultStartingWeight + raisedExercise.increment.large, message: "Exceptional lift!", celebrationLevel: .gold),
                    targetReps: 8,
                    onRest: {}
                )
            case "rest":
                V5RestScreen(elapsed: "1:24", bpm: 138, ready: false)
            case "rest-ready":
                V5RestScreen(elapsed: "2:08", bpm: 112, ready: true)
            case "rest-choice-mock":
                V5RestChoiceMockScreen(elapsed: "0:13", nextExercise: "Incline Press", nextWeight: 40)
            case "summary":
                SessionSummaryView(exercises: Self.queueExercises, records: Self.summaryRecords, displayVolumeOverride: 4680, onDone: {})
            default:
                MusclePickerView(
                    selectedGroups: ["chest", "tricep"],
                    onSelectGroup: { _ in },
                    onStartWorkout: {}
                )
            }
        }
    }

    static var queueExercises: [Exercise] {
        [
            benchPress(weight: 50),
            Exercise(id: "chest_fly", name: "Chest Fly", muscleGroups: ["chest", "tricep"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 10, large: 10), isBodyweight: false, isIsometric: false, weightType: .machine, minimumWeight: 10, defaultStartingWeight: 80),
            tricepPushdown,
            Exercise(id: "skull_crusher", name: "Skull Crusher", muscleGroups: ["tricep"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 5, large: 5), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 5, defaultStartingWeight: 40)
        ]
    }

    static var tricepPushdown: Exercise {
        Exercise(id: "tricep_cable_pushdown", name: "Tricep Cable Pushdown", muscleGroups: ["tricep"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 5, large: 5), isBodyweight: false, isIsometric: false, weightType: .cable, minimumWeight: 5, defaultStartingWeight: 40)
    }

    static func benchPress(weight: Double) -> Exercise {
        Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest", "tricep"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 10, large: 10), isBodyweight: false, isIsometric: false, weightType: .machine, minimumWeight: 10, defaultStartingWeight: weight)
    }

    static func selectedExercise() -> Exercise {
        let exerciseID = ProcessInfo.processInfo.environment["WRISTCOACH_V5_EXERCISE_ID"]
        let exercise = ExerciseLibrary.load()
            .groups
            .flatMap(\.exercises)
            .first { $0.id == exerciseID } ?? benchPress(weight: 135)

        guard let weightValue = ProcessInfo.processInfo.environment["WRISTCOACH_V5_WEIGHT"],
              let weight = Double(weightValue) else {
            return exercise
        }
        return exercise.withStartingWeight(weight)
    }

    static var summaryRecords: [ExerciseRecord] {
        [
            ExerciseRecord(exerciseId: "bench_press", targetWeight: 140, targetReps: 8, actualReps: 10),
            ExerciseRecord(exerciseId: "chest_fly", targetWeight: 80, targetReps: 8, actualReps: 8),
            ExerciseRecord(exerciseId: "tricep_cable_pushdown", targetWeight: 40, targetReps: 8, actualReps: 8),
            ExerciseRecord(exerciseId: "skull_crusher", targetWeight: 40, targetReps: 8, actualReps: 8)
        ]
    }
}

private extension Exercise {
    func withStartingWeight(_ weight: Double) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroups: muscleGroups,
            defaultThreshold: defaultThreshold,
            increment: increment,
            isBodyweight: isBodyweight,
            isIsometric: isIsometric,
            weightType: weightType,
            minimumWeight: minimumWeight,
            defaultStartingWeight: weight
        )
    }
}

struct V5PresetScreen: View {
    let exercise: Exercise
    let weightRaised: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(exercise.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.53))
                .tracking(0.6)
                .textCase(.uppercase)
            Text(weightLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(weightRaised ? Color(red: 0.18, green: 0.82, blue: 0.33) : .white)
            Text("Set 1 of 3")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.33))
                .padding(.bottom, 9)

            Text("GO")
                .font(.system(size: 22, weight: .heavy))
                .tracking(0.8)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Color(red: 0.18, green: 0.82, blue: 0.33)))
                .foregroundColor(.black)
                .overlay(Circle().stroke(Color(red: 0.18, green: 0.82, blue: 0.33).opacity(0.15), lineWidth: 12))
                .padding(.bottom, 7)

            Text("Tap when ready to lift")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.27))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var weightLabel: String {
        if exercise.isBodyweight {
            return "Bodyweight"
        }
        return weightRaised ? "\(Int(exercise.defaultStartingWeight)) lb ↑" : "\(Int(exercise.defaultStartingWeight)) lb"
    }
}

struct V5CountingScreen: View {
    let exercise: Exercise
    let reps: Int
    let targetReps: Int
    let weightRaised: Bool

    private var overTarget: Bool { reps > targetReps }
    private var ringColor: Color { overTarget ? Color(red: 1.0, green: 0.84, blue: 0.04) : Color(red: 0.04, green: 0.52, blue: 1.0) }

    var body: some View {
        VStack(spacing: 3) {
            Text(exercise.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(white: 0.53))
                .tracking(0.8)
                .textCase(.uppercase)
            Text(weightLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(weightRaised ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.67))

            ZStack {
                Circle()
                    .stroke(Color(white: 0.10), lineWidth: 9)
                    .frame(width: 92, height: 92)
                Circle()
                    .trim(from: 0, to: min(1, Double(reps) / Double(targetReps)))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-90))
                if overTarget {
                    Circle()
                        .stroke(ringColor.opacity(0.20), lineWidth: 2)
                        .frame(width: 92, height: 92)
                }
                VStack(spacing: 1) {
                    Text("\(reps)")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundColor(overTarget ? ringColor : .white)
                    Text(overTarget ? "keep going" : "of \(targetReps)")
                        .font(.system(size: 10))
                        .foregroundColor(overTarget ? Color(red: 0.34, green: 0.27, blue: 0.0) : Color(white: 0.27))
                }
            }
            .padding(.vertical, 1)

            Text(motivation)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(overTarget ? ringColor : Color(red: 1.0, green: 0.62, blue: 0.04))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background((overTarget ? ringColor : Color(red: 1.0, green: 0.62, blue: 0.04)).opacity(0.10))
                .cornerRadius(8)
                .lineLimit(1)

            Text("■ STOP")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(Color(white: 0.11))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.20), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var weightLabel: String {
        let marker = weightRaised ? " ↑" : ""
        if exercise.isBodyweight {
            return "Bodyweight\(marker) · Set 1/3"
        }
        return "\(Int(exercise.defaultStartingWeight)) lb\(marker) · Set 1/3"
    }

    private var motivation: String {
        if overTarget {
            return weightRaised ? "New weight, extra reps!" : "Beyond target. Keep going."
        }
        return "💪 2 more, push it!"
    }
}

struct V5RestScreen: View {
    let elapsed: String
    let bpm: Int
    let ready: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("ELAPSED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(white: 0.40))
                    .tracking(1.0)
                Spacer()
            }
            .padding(.bottom, 6)

            Text("\(bpm)")
                .font(.system(size: 44, weight: .heavy))
                .foregroundColor(metricColor)
            Text("BPM ♥")
                .font(.system(size: 11))
                .foregroundColor(metricColor.opacity(0.70))
                .padding(.bottom, 10)
            HStack(spacing: 0) {
                Text("Target ")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.33))
                Text("115 BPM")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.67))
                if ready {
                    Text(" ✓")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                }
            }
            .padding(.bottom, 8)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.11))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ready ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(red: 1.0, green: 0.22, blue: 0.37))
                        .frame(width: proxy.size.width * (ready ? 1.0 : 0.4))
                }
            }
            .frame(height: 4)
            .padding(.bottom, 12)
            Text("Ready →")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(ready ? .black : Color(white: 0.27))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(ready ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color.black)
                .cornerRadius(11)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(ready ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.20), lineWidth: 1.5))
            Text("Next: Chest Fly · 50 lb")
                .font(.system(size: 9))
                .foregroundColor(ready ? Color(white: 0.33) : Color(white: 0.23))
                .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var metricColor: Color {
        ready ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(red: 1.0, green: 0.22, blue: 0.37)
    }
}

struct V5RestChoiceMockScreen: View {
    let elapsed: String
    let nextExercise: String
    let nextWeight: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ELAPSED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(white: 0.40))
                    .tracking(1.0)
                Spacer()
            }
            .padding(.bottom, 18)

            Text(elapsed)
                .font(.system(size: 56, weight: .heavy))
                .foregroundColor(Color(red: 1.0, green: 0.22, blue: 0.37))
                .minimumScaleFactor(0.85)

            Text("TIMER ONLY")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 1.0, green: 0.22, blue: 0.37).opacity(0.75))
                .padding(.top, 7)
                .padding(.bottom, 13)

            Text("No HR 90s rest")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.52))
                .padding(.bottom, 10)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.11))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 1.0, green: 0.22, blue: 0.37))
                        .frame(width: proxy.size.width * 0.15)
                }
            }
            .frame(height: 4)
            .padding(.bottom, 14)

            HStack(spacing: 8) {
                Text("Repeat")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color(white: 0.11))
                    .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                    .cornerRadius(9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color(red: 0.18, green: 0.82, blue: 0.33), lineWidth: 1.5)
                    )

                Text("Next →")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                    .foregroundColor(.black)
                    .cornerRadius(9)
            }

            Text("Next: \(nextExercise) · \(nextWeight) lb")
                .font(.system(size: 9))
                .foregroundColor(Color(white: 0.33))
                .padding(.top, 8)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
