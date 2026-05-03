import AVFoundation
import Foundation
import HealthKit

enum ReadinessStatus: Equatable {
    case checking
    case ready(String)
    case degraded(String)
    case failed(String)

    var label: String {
        switch self {
        case .checking:
            return "Checking"
        case .ready(let message), .degraded(let message), .failed(let message):
            return message
        }
    }

    var canContinue: Bool {
        switch self {
        case .checking, .failed:
            return false
        case .ready, .degraded:
            return true
        }
    }
}

struct WorkoutReadiness: Equatable {
    var healthKit: ReadinessStatus
    var workoutSession: ReadinessStatus
    var audio: ReadinessStatus
    var motion: ReadinessStatus

    static let checking = WorkoutReadiness(
        healthKit: .checking,
        workoutSession: .checking,
        audio: .checking,
        motion: .checking
    )

    static func optimisticEntry(motionAvailable: Bool) -> WorkoutReadiness {
        WorkoutReadiness(
            healthKit: .degraded("Timer-only rest"),
            workoutSession: .degraded("Starting session"),
            audio: .degraded("Audio warming"),
            motion: motionAvailable ? .ready("Auto-count ready") : .degraded("Manual reps")
        )
    }

    var canEnterActiveSet: Bool {
        healthKit.canContinue
            && workoutSession.canContinue
            && audio.canContinue
            && motion.canContinue
    }

    var degradedHR: Bool {
        if case .degraded = healthKit {
            return true
        }
        return false
    }

    var usesManualRepMode: Bool {
        if case .degraded = motion {
            return true
        }
        return false
    }
}

@MainActor
protocol WorkoutSessionController {
    func prepareForWorkout(
        speechAnnouncer: SpeechAnnouncer,
        motionSource: MotionSource
    ) async -> WorkoutReadiness
    func endWorkout() async
}

@MainActor
final class HealthKitWorkoutSessionController: NSObject, WorkoutSessionController {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func prepareForWorkout(
        speechAnnouncer: SpeechAnnouncer,
        motionSource: MotionSource
    ) async -> WorkoutReadiness {
        let healthStatus = await requestHealthKitReadiness()
        let sessionStatus = await startWorkoutSession()
        let audioStatus = prepareAudio(speechAnnouncer)
        let motionStatus: ReadinessStatus = motionSource.isAvailable
            ? .ready("Auto-count ready")
            : .degraded("Manual reps")

        return WorkoutReadiness(
            healthKit: healthStatus,
            workoutSession: sessionStatus,
            audio: audioStatus,
            motion: motionStatus
        )
    }

    func endWorkout() async {
        guard let session, let builder else { return }
        session.end()
        do {
            try await builder.endCollection(at: Date())
            _ = try await builder.finishWorkout()
        } catch {
            // The foundation slice tolerates finish failures; HealthKit owns partial cleanup.
        }
        self.session = nil
        self.builder = nil
    }

    private func requestHealthKitReadiness() async -> ReadinessStatus {
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let workoutType = HKObjectType.workoutType() as HKSampleType? else {
            return .degraded("Timer-only rest")
        }

        do {
            try await healthStore.requestAuthorization(toShare: [workoutType], read: [heartRateType])
            return .ready("HR ready")
        } catch {
            return .degraded("No HR")
        }
    }

    private func startWorkoutSession() async -> ReadinessStatus {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            self.session = session
            self.builder = builder
            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())
            return .ready("Workout active")
        } catch {
            return .failed("Workout failed")
        }
    }

    private func prepareAudio(_ speechAnnouncer: SpeechAnnouncer) -> ReadinessStatus {
        speechAnnouncer.say("Audio ready")
        return .ready("Audio test spoken")
    }
}
