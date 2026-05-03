import Foundation

protocol RepDetectorDelegate: AnyObject {
    func repCountDidChange(_ repCount: Int)
    func fatigueDetected()
}

class RepDetector {
    private let threshold: Double
    private let debounceSeconds: Double = 0.4
    private let bufferSize: Int = 30
    private let centerIdx: Int = 15

    private var sampleBuffer: [(t: TimeInterval, mag: Double)] = []
    private var lastRepTime: TimeInterval = 0
    private(set) var repCount: Int = 0
    private(set) var repIntervals: [Double] = []
    private(set) var baselineIOI: Double? = nil
    private(set) var lastTwoFatigued: (Bool, Bool) = (false, false)

    weak var delegate: RepDetectorDelegate?

    init(threshold: Double) {
        self.threshold = threshold
    }

    func processSample(t: TimeInterval, userAcceleration: SIMD3<Double>) {
        let mag = sqrt(userAcceleration.x * userAcceleration.x
                     + userAcceleration.y * userAcceleration.y
                     + userAcceleration.z * userAcceleration.z)

        sampleBuffer.append((t, mag))
        if sampleBuffer.count > bufferSize {
            sampleBuffer.removeFirst()
        }

        guard sampleBuffer.count == bufferSize else {
            return
        }

        // Center-of-window local max: the sample at index centerIdx must be the max
        // of the full 30-sample buffer AND above threshold AND past debounce.
        let centerSample = sampleBuffer[centerIdx]
        guard centerSample.mag > threshold else {
            return
        }

        let windowMax = sampleBuffer.map { $0.mag }.max() ?? 0
        guard centerSample.mag >= windowMax else {
            return
        }

        guard centerSample.t - lastRepTime > debounceSeconds else {
            return
        }

        // Count the rep
        repCount += 1

        if lastRepTime > 0 {
            let interval = centerSample.t - lastRepTime
            repIntervals.append(interval)
            analyzeIOI(interval)
        }

        lastRepTime = centerSample.t
        delegate?.repCountDidChange(repCount)
    }

    func reset() {
        sampleBuffer.removeAll(keepingCapacity: true)
        lastRepTime = 0
        repCount = 0
        repIntervals.removeAll(keepingCapacity: true)
        baselineIOI = nil
        lastTwoFatigued = (false, false)
    }

    private func analyzeIOI(_ interval: Double) {
        // Skip first 3 reps for baseline calculation (startup is noisy)
        guard repIntervals.count >= 4 else {
            return
        }

        // Only set baseline once
        guard baselineIOI == nil else {
            // Check for fatigue on this interval
            if let baseline = baselineIOI, interval > baseline * 1.3 {
                // This rep is fatigued
                lastTwoFatigued = (lastTwoFatigued.1, true)
                delegate?.fatigueDetected()
            } else {
                lastTwoFatigued = (lastTwoFatigued.1, false)
            }
            return
        }

        // Calculate baseline from reps 2, 3, 4 (indices 1, 2, 3 in repIntervals)
        if repIntervals.count == 4 {
            let indices = repIntervals.indices
            let sample1 = repIntervals[indices[1]]
            let sample2 = repIntervals[indices[2]]
            let sample3 = repIntervals[indices[3]]
            baselineIOI = (sample1 + sample2 + sample3) / 3.0
        }
    }
}
