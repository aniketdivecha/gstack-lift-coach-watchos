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
