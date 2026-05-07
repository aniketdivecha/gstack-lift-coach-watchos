import SwiftUI

struct ActiveSetView: View, @unchecked Sendable {
    @StateObject private var setController: SetSessionController
    @State private var currentWeight: Double
    let exercise: Exercise
    let targetReps: Int
    let manualMode: Bool
    let onStop: (SetResult) -> Void

    init(
        exercise: Exercise,
        targetReps: Int,
        manualMode: Bool = false,
        initialWeight: Double? = nil,
        initialRepCount: Int = 0,
        initialCountingStarted: Bool = false,
        initialFatigued: Bool = false,
        onStop: @escaping (SetResult) -> Void
    ) {
        self.exercise = exercise
        self.targetReps = targetReps
        self.onStop = onStop
        self.manualMode = manualMode
        _currentWeight = State(initialValue: initialWeight ?? exercise.defaultStartingWeight)
        _setController = StateObject(
            wrappedValue: SetSessionController(
                exercise: exercise,
                targetReps: targetReps,
                manualMode: manualMode,
                initialRepCount: initialRepCount,
                initialCountingStarted: initialCountingStarted,
                initialFatigued: initialFatigued
            )
        )
    }

    var body: some View {
        Group {
            if setController.isCountingStarted {
                countingBody
            } else {
                presetBody
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var presetBody: some View {
        VStack(spacing: 5) {
            Text(exercise.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.53))
                .tracking(0.6)
                .textCase(.uppercase)
                .lineLimit(1)

            weightControl

            Button(action: setController.start) {
                Text("GO")
                    .font(.system(size: 22, weight: .heavy))
                    .tracking(0.8)
            }
            .frame(width: 86, height: 86)
            .background(Circle().fill(Color(red: 0.18, green: 0.82, blue: 0.33)))
            .foregroundColor(.black)
            .overlay(
                Circle()
                    .stroke(Color(red: 0.18, green: 0.82, blue: 0.33).opacity(0.18), lineWidth: 11)
            )
            .buttonStyle(.plain)
            .padding(.bottom, 7)

            Text("Tap when ready to lift")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.27))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var countingBody: some View {
        VStack(spacing: manualMode ? 4 : 6) {
            if !manualMode {
                Text("\(weightLabel) · Set 1/3")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(isOverTarget ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.67))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            ZStack {
                Circle()
                    .stroke(Color(white: 0.1), lineWidth: 8)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                if isOverTarget {
                    Circle()
                        .stroke(ringColor.opacity(0.20), lineWidth: 2)
                        .frame(width: ringSize, height: ringSize)
                }

                VStack(spacing: 1) {
                    Text("\(setController.repCount)")
                        .font(.system(size: manualMode ? 32 : 38, weight: .heavy))
                        .foregroundColor(isOverTarget ? ringColor : .white)
                    Text(isOverTarget ? "keep going" : "of \(targetReps)")
                        .font(.system(size: 10))
                        .foregroundColor(isOverTarget ? Color(red: 0.34, green: 0.27, blue: 0.0) : Color(white: 0.27))
                }
            }

            Text(motivationText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isOverTarget ? ringColor : Color(red: 1.0, green: 0.62, blue: 0.04))
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .padding(.horizontal, 8)
                .background((isOverTarget ? ringColor : Color(red: 1.0, green: 0.62, blue: 0.04)).opacity(0.10))
                .cornerRadius(8)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if manualMode {
                manualControls
            }

            Button(action: stopRepDetection) {
                Text("■ STOP")
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .background(Color(white: 0.11))
            .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.20), lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var manualControls: some View {
        HStack(spacing: 8) {
            Button(action: setController.decrementManualRep) {
                Text("-")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .background(Color(white: 0.11))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.20), lineWidth: 1)
            )
            .buttonStyle(.plain)

            Button(action: setController.incrementManualRep) {
                Text("+")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .background(Color(white: 0.11))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.20), lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
    }

    private var weightControl: some View {
        HStack(spacing: 10) {
            Button(action: decrementWeight) {
                Text("-")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 24)
            }
            .background(Color(white: 0.11))
            .foregroundColor(canEditWeight ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.27))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canEditWeight ? Color(white: 0.20) : Color(white: 0.12), lineWidth: 1)
            )
            .buttonStyle(.plain)
            .disabled(!canEditWeight)

            Text(weightLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(minWidth: 52)

            Button(action: incrementWeight) {
                Text("+")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 24)
            }
            .background(Color(white: 0.11))
            .foregroundColor(canEditWeight ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.27))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canEditWeight ? Color(white: 0.20) : Color(white: 0.12), lineWidth: 1)
            )
            .buttonStyle(.plain)
            .disabled(!canEditWeight)
        }
    }

    private var ringSize: CGFloat {
        manualMode ? 74 : 92
    }

    private var weightLabel: String {
        exercise.isBodyweight ? "Bodyweight" : "\(Int(currentWeight)) lb"
    }

    private var canEditWeight: Bool {
        !exercise.isBodyweight && !exercise.isIsometric && setController.isCountingStarted == false
    }

    private var weightStep: Double {
        max(exercise.increment.large, 1)
    }

    private var isOverTarget: Bool {
        setController.repCount > targetReps
    }

    private var ringProgress: Double {
        guard targetReps > 0 else { return 0 }
        return min(1, Double(setController.repCount) / Double(targetReps))
    }

    private var ringColor: Color {
        isOverTarget ? Color(red: 1.0, green: 0.84, blue: 0.04) : Color(red: 0.04, green: 0.52, blue: 1.0)
    }

    private var motivationText: String {
        if isOverTarget {
            return "Beyond target. Keep going."
        }
        if manualMode {
            return "Manual count. Use +/- if needed."
        }
        if setController.isFatigued {
            return "💪 2 more, push it!"
        }
        return "\(setController.remainingReps) reps to go"
    }

    private func stopRepDetection() {
        let stopped = setController.stop()
        onStop(SetResult(
            actualReps: stopped.actualReps,
            repIntervals: stopped.repIntervals,
            struggled: stopped.struggled,
            manualOverride: stopped.manualOverride,
            targetWeight: exercise.isBodyweight ? nil : currentWeight
        ))
    }

    private func incrementWeight() {
        guard canEditWeight else { return }
        currentWeight += weightStep
    }

    private func decrementWeight() {
        guard canEditWeight else { return }
        currentWeight = max(exercise.minimumWeight, currentWeight - weightStep)
    }
}

struct SetCompleteView: View {
    let exercise: Exercise
    let result: SetResult
    let overload: OverloadResult
    let targetReps: Int
    let onRest: () -> Void

    var body: some View {
        VStack(spacing: isGold ? 3 : 8) {
            Text(exercise.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.40))
                .tracking(0.8)
                .textCase(.uppercase)
                .lineLimit(1)

            Text("\(result.actualReps)")
                .font(.system(size: isGold ? 42 : 44, weight: isGold ? .black : .heavy))
                .foregroundColor(heroColor)
                .lineLimit(1)

            Text(detailLine)
                .font(.system(size: isGold ? 9.5 : 11))
                .foregroundColor(isGold ? Color(red: 0.47, green: 0.40, blue: 0.0) : Color(white: 0.40))
                .lineLimit(1)
                .padding(.bottom, isGold ? 0 : 2)

            Text("\"\(overload.message)\"")
                .font(.system(size: isGold ? 10 : 11, weight: isGold ? .bold : .regular))
                .foregroundColor(isGold ? heroColor : Color(white: 0.67))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isGold ? 4 : 6)
                .padding(.horizontal, 10)
                .background((isGold ? heroColor : Color.white).opacity(isGold ? 0.10 : 0.07))
                .cornerRadius(8)
                .lineLimit(1)

            if isGold {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next session")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(red: 0.29, green: 0.48, blue: 0.0))
                        .tracking(0.6)
                        .textCase(.uppercase)
                    Text("\(Int(overload.newWeight)) lb × \(targetReps)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.33))
                    Text(nextReason)
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(red: 0.23, green: 0.42, blue: 0.0))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color(red: 0.05, green: 0.10, blue: 0.0))
                .cornerRadius(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color(red: 0.16, green: 0.29, blue: 0.0), lineWidth: 1)
                )
            }

            Button(action: onRest) {
                Text("Rest →")
                    .font(.system(size: isGold ? 11 : 12, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .frame(height: isGold ? 27 : 34)
            .background(isGold ? Color(red: 0.18, green: 0.82, blue: 0.33) : Color(white: 0.11))
            .foregroundColor(isGold ? .black : Color(red: 0.18, green: 0.82, blue: 0.33))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isGold ? Color.clear : Color(red: 0.18, green: 0.82, blue: 0.33), lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var isGold: Bool {
        if case .gold = overload.celebrationLevel {
            return true
        }
        return false
    }

    private var heroColor: Color {
        isGold ? Color(red: 1.0, green: 0.84, blue: 0.04) : Color(red: 0.18, green: 0.82, blue: 0.33)
    }

    private var detailLine: String {
        let weight = exercise.isBodyweight ? "bodyweight" : "\(Int(exercise.defaultStartingWeight)) lb"
        if result.actualReps > targetReps {
            return "reps · \(weight) · +\(result.actualReps - targetReps) bonus"
        }
        return "reps · \(weight)"
    }

    private var nextReason: String {
        if exercise.defaultStartingWeight > 135 {
            return "\(Int(exercise.defaultStartingWeight)) lb too easy"
        }
        return "Mastered \(Int(exercise.defaultStartingWeight))"
    }
}

#Preview {
    ActiveSetView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), targetReps: 8, onStop: { _ in })
}
