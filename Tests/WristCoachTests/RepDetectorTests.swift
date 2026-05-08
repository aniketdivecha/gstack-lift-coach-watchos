import Foundation
import Testing

@Suite("RepDetector")
struct RepDetectorTests {
    @Test("fixture counts reps and reports fatigue without completing the set")
    func fixtureCountsRepsAndReportsFatigue() throws {
        let fixture = try FixtureLoader.benchPress8Reps()
        let detector = RepDetector(threshold: fixture.threshold)
        let delegate = RepDetectorSpy()
        detector.delegate = delegate

        for sample in fixture.samples {
            detector.processSample(t: sample.t, userAcceleration: sample.acceleration)
        }

        #expect(detector.repCount == fixture.targetReps)
        #expect(delegate.repCounts.last == fixture.targetReps)
        #expect(delegate.fatigueEvents >= 2)
        #expect(detector.lastTwoFatigued.0 == true)
        #expect(detector.lastTwoFatigued.1 == true)
    }

    @Test("calibration derives signature and signature detector counts matching reps")
    func calibrationSignatureCountsMatchingReps() throws {
        let samples = makeTwoPhaseSamples(reps: 4)
        let collector = RepCalibrationCollector(
            targetReps: 4,
            threshold: 0.4
        )
        var signature: RepMotionSignature?

        for sample in samples {
            signature = collector.processSample(t: sample.t, userAcceleration: sample.acceleration) ?? signature
        }

        let calibratedSignature = try #require(signature)
        let detector = RepDetector(threshold: 0.4, signature: calibratedSignature)

        for sample in samples {
            detector.processSample(t: sample.t, userAcceleration: sample.acceleration)
        }

        #expect(calibratedSignature.supportsTwoPhaseCounting)
        #expect(collector.repCount == 4)
        #expect(detector.repCount == 4)
    }

    @Test("signature detector finalizes a high-confidence final half rep on stop")
    func finalizesHighConfidenceFinalHalfRep() throws {
        let signature = try calibratedTwoPhaseSignature(reps: 4)
        let detector = RepDetector(threshold: 0.4, signature: signature)

        for sample in makeTwoPhaseSamples(reps: 3, includesFinalHalf: true) {
            detector.processSample(t: sample.t, userAcceleration: sample.acceleration)
        }

        #expect(detector.repCount == 3)
        #expect(detector.finalizePendingRep() == 4)
        #expect(detector.repCount == 4)
    }

    @Test("signature derivation removes two standard deviation outliers")
    func signatureDerivationRemovesOutliers() throws {
        let normalVectors = [
            RepMotionVector(values: [1.00, 0.10, 0.20, 1.05, 0.30]),
            RepMotionVector(values: [1.04, 0.12, 0.18, 1.08, 0.32]),
            RepMotionVector(values: [0.97, 0.09, 0.21, 1.02, 0.29]),
            RepMotionVector(values: [1.03, 0.11, 0.19, 1.07, 0.31]),
            RepMotionVector(values: [0.99, 0.10, 0.20, 1.04, 0.30]),
            RepMotionVector(values: [1.02, 0.12, 0.22, 1.06, 0.33]),
            RepMotionVector(values: [0.98, 0.08, 0.19, 1.03, 0.28])
        ]
        let outlier = RepMotionVector(values: [8.0, 4.0, 4.0, 9.0, 5.0])
        let signature = try #require(RepMotionSignature.derive(from: normalVectors + [outlier]))

        #expect(signature.mean[0] < 1.1)
        #expect(signature.mean[3] < 1.1)
    }
}

private func calibratedTwoPhaseSignature(reps: Int) throws -> RepMotionSignature {
    let collector = RepCalibrationCollector(targetReps: reps, threshold: 0.4)
    var signature: RepMotionSignature?

    for sample in makeTwoPhaseSamples(reps: reps) {
        signature = collector.processSample(t: sample.t, userAcceleration: sample.acceleration) ?? signature
    }

    return try #require(signature)
}

private struct TestMotionSample {
    let t: TimeInterval
    let acceleration: SIMD3<Double>
}

private func makeTwoPhaseSamples(
    reps: Int,
    includesFinalHalf: Bool = false,
    finalHalfMagnitude: Double = 1.0
) -> [TestMotionSample] {
    let sampleRateHz = 30.0
    let baselineNoise = 0.02
    var events: [(time: TimeInterval, x: Double)] = []

    for repIndex in 0..<reps {
        let baseTime = 1.0 + Double(repIndex) * 1.4
        events.append((time: baseTime, x: 1.0))
        events.append((time: baseTime + 0.6, x: -1.0))
    }

    if includesFinalHalf {
        let finalHalfTime = 1.0 + Double(reps) * 1.4
        events.append((time: finalHalfTime, x: finalHalfMagnitude))
    }

    let duration = (events.map(\.time).max() ?? 0) + 1.1
    let sampleCount = Int(duration * sampleRateHz)

    return (0...sampleCount).map { index in
        let t = Double(index) / sampleRateHz
        let event = events.first { abs($0.time - t) < 0.0001 }
        return TestMotionSample(
            t: t,
            acceleration: SIMD3<Double>(event?.x ?? baselineNoise, 0, 0)
        )
    }
}

private final class RepDetectorSpy: RepDetectorDelegate {
    var repCounts: [Int] = []
    var fatigueEvents = 0

    func repCountDidChange(_ repCount: Int) {
        repCounts.append(repCount)
    }

    func fatigueDetected() {
        fatigueEvents += 1
    }
}
