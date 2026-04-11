import HealthKit

protocol HeartRateSource {
    var currentBPM: AsyncStream<Double> { get }
    func start()
    func stop()
}

final class HealthKitHeartRateSource: HeartRateSource {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var query: HKAnchoredObjectQuery?
    private let throttleDuration: TimeInterval = 1.0
    private var lastUpdateDate: Date?
    private var bpmContinuation: AsyncStream<Double>.Continuation?

    var currentBPM: AsyncStream<Double> {
        AsyncStream<Double> { continuation in
            self.bpmContinuation = continuation
        }
    }

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let types: Set<HKQuantityType> = [.quantityType(forIdentifier: .heartRate)!]
        healthStore.requestAuthorization(toShare: nil, read: types) { [weak self] success, _ in
            guard success, let self = self else { return }
            self.startQuery()
        }
    }

    func stop() {
        query?.end()
        query = nil
        bpmContinuation?.finish()
        bpmContinuation = nil
    }

    private func startQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let anchor = query?.anchor
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, sampleObjects, newAnchor, error in
            guard let self = self,
                  let samples = sampleObjects as? [HKQuantitySample],
                  error == nil else {
                return
            }

            for sample in samples {
                self.handleHRUpdate(sample)
            }

            self.query?.anchor = newAnchor
            self.query = query
        }

        query?.updateHandler = { [weak self] query, _, _, error in
            guard let self = self, error == nil else {
                return
            }

            if let samples = query.samples as? [HKQuantitySample] {
                for sample in samples {
                    self.handleHRUpdate(sample)
                }
            }
        }

        healthStore.execute(query)
        self.query = query
    }

    private func handleHRUpdate(_ sample: HKQuantitySample) {
        let now = Date()
        guard let lastUpdateDate = lastUpdateDate,
              now.timeIntervalSince(lastUpdateDate) < throttleDuration else {
            self.lastUpdateDate = now
            return
        }

        let bpm = sample.quantity.doubleValue(for: .count().unit(.minute()))
        bpmContinuation?.yield(bpm)
    }
}
