import SwiftUI

struct WorkoutReadinessView: View {
    let exercise: Exercise
    let readiness: WorkoutReadiness
    let onContinue: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(headerText)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: 5) {
                readinessRow(title: "HealthKit", status: readiness.healthKit)
                readinessRow(title: "Workout", status: readiness.workoutSession)
                readinessRow(title: "Audio", status: readiness.audio)
                readinessRow(title: "Motion", status: readiness.motion)
            }

            Spacer(minLength: 2)

            if readiness.canEnterActiveSet {
                Button(action: onContinue) {
                    Text(readiness.usesManualRepMode ? "Use manual reps" : "Enter set")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 32)
                .background(Color(red: 0.18, green: 0.82, blue: 0.33))
                .foregroundColor(.black)
                .cornerRadius(8)
                .buttonStyle(.plain)
            } else {
                Button(action: onRetry) {
                    Text(readiness.hasFailure ? "Retry checks" : "Checking watch")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 32)
                .background(Color(white: 0.11))
                .foregroundColor(readiness.hasFailure ? .white : Color(white: 0.45))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.20), lineWidth: 1)
                )
                .disabled(!readiness.hasFailure)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
    }

    private func readinessRow(title: String, status: ReadinessStatus) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: status))
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(Color(white: 0.20), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(detail(for: title, status: status))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(Color(white: 0.55))
                    .lineLimit(1)
            }

            Spacer()

            if let badge = badge(for: status) {
                Text(badge)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(color(for: status))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
                    .background(color(for: status).opacity(0.10))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(Color(white: 0.067))
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(status.isAttentionState ? color(for: status).opacity(0.65) : Color(white: 0.12), lineWidth: 1)
        )
        .accessibilityLabel("\(title), \(status.label)")
    }

    private var headerText: String {
        if readiness.canEnterActiveSet {
            return readiness.usesManualRepMode ? "Manual reps ready" : "\(exercise.name) ready"
        }
        if readiness.hasFailure {
            return "Needs attention"
        }
        return "Checking \(exercise.name)"
    }

    private func color(for status: ReadinessStatus) -> Color {
        switch status {
        case .checking:
            return Color(white: 0.33)
        case .ready:
            return Color(red: 0.18, green: 0.82, blue: 0.33)
        case .degraded:
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .failed:
            return Color(red: 1.0, green: 0.22, blue: 0.37)
        }
    }

    private func badge(for status: ReadinessStatus) -> String? {
        switch status {
        case .checking:
            return nil
        case .ready:
            return "OK"
        case .degraded:
            return "ALT"
        case .failed:
            return "FAIL"
        }
    }

    private func detail(for title: String, status: ReadinessStatus) -> String {
        switch status {
        case .checking:
            switch title {
            case "HealthKit":
                return "Heart rate access"
            case "Workout":
                return "Starting session"
            case "Audio":
                return "Testing cue"
            case "Motion":
                return "Auto-count check"
            default:
                return "Checking"
            }
        case .ready, .degraded, .failed:
            return status.label
        }
    }
}

private extension ReadinessStatus {
    var isAttentionState: Bool {
        switch self {
        case .degraded, .failed:
            return true
        case .checking, .ready:
            return false
        }
    }
}

private extension WorkoutReadiness {
    var hasFailure: Bool {
        healthKit.isFailed || workoutSession.isFailed || audio.isFailed || motion.isFailed
    }
}

private extension ReadinessStatus {
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

#Preview {
    WorkoutReadinessView(
        exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0),
        readiness: .checking,
        onContinue: {},
        onRetry: {}
    )
}
