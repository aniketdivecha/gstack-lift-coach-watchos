import HealthKit

protocol HeartRateSource {
    var currentBPM: AsyncStream<Double> { get }
    func start()
    func stop()
}

final class HealthKitHeartRateSource: HeartRateSource, @unchecked Sendable {
    private let healthStore = HKHealthStore()
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
        if let query = query {
            healthStore.stop(query)
        }
        query = nil
        bpmContinuation?.finish()
        bpmContinuation = nil
    }

    private func startQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: HKQueryAnchor(fromValue: 0),
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, sampleObjects, _, newAnchor, error in
            guard let self = self,
                  let samples = sampleObjects as? [HKQuantitySample],
                  error == nil else {
                return
            }

            for sample in samples {
                self.handleHRUpdate(sample)
            }
        }

        healthStore.execute(query)
        self.query = query
    }

    private func handleHRUpdate(_ sample: HKQuantitySample) {
        let now = Date()
        if let lastUpdateDate,
           now.timeIntervalSince(lastUpdateDate) < throttleDuration {
            return
        }

        lastUpdateDate = now
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = sample.quantity.doubleValue(for: unit)
        bpmContinuation?.yield(bpm)
    }
}
