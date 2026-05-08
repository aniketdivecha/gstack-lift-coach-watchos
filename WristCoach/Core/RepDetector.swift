import Foundation

private enum RepMotionTuning {
    static let minimumStandardDeviation = 0.03
    static let normalStandardDeviationMultiplier = 2.0
    static let highConfidenceStandardDeviationMultiplier = 1.25
    static let normalDirectionSimilarity = 0.55
    static let highConfidenceDirectionSimilarity = 0.85
    static let normalMagnitudeFraction = 0.65
    static let highConfidenceMagnitudeFraction = 0.85
    static let peakDebounceSeconds = 0.25
    static let legacyDebounceSeconds = 0.4
    static let minimumPhaseGapSeconds = 0.20
    static let maximumPhaseGapSeconds = 4.0
    static let finalPartialGraceSeconds = 3.0
    static let calibrationOppositeDirectionSimilarity = -0.55
}

struct RepMotionVector: Codable, Equatable {
    static let dimensionCount = 5

    let values: [Double]

    init(values: [Double]) {
        self.values = values
    }

    var motionMagnitude: Double {
        guard values.indices.contains(3) else {
            return directionalMagnitude(values)
        }

        return abs(values[3])
    }
}

struct RepMotionPhaseSignature: Codable, Equatable {
    let mean: [Double]
    let standardDeviation: [Double]

    var isValid: Bool {
        mean.count == RepMotionVector.dimensionCount
            && standardDeviation.count == RepMotionVector.dimensionCount
    }

    var referenceMagnitude: Double {
        guard mean.indices.contains(3) else {
            return directionalMagnitude(mean)
        }

        return abs(mean[3])
    }

    func contains(_ vector: RepMotionVector, standardDeviationMultiplier: Double = 2.0) -> Bool {
        guard isValid, vector.values.count == mean.count else {
            return false
        }

        for index in mean.indices {
            let allowedDistance = max(
                standardDeviation[index],
                RepMotionTuning.minimumStandardDeviation
            ) * standardDeviationMultiplier

            if abs(vector.values[index] - mean[index]) > allowedDistance {
                return false
            }
        }

        return true
    }

    func normalizedDistance(to vector: RepMotionVector) -> Double? {
        guard isValid, vector.values.count == mean.count else {
            return nil
        }

        let squaredDistance = mean.indices.reduce(0.0) { total, index in
            let spread = max(
                standardDeviation[index],
                RepMotionTuning.minimumStandardDeviation
            )
            let normalizedDelta = (vector.values[index] - mean[index]) / spread
            return total + normalizedDelta * normalizedDelta
        }

        return sqrt(squaredDistance / Double(mean.count))
    }

    func directionSimilarity(to vector: RepMotionVector) -> Double {
        directionalCosine(mean, vector.values)
    }

    fileprivate static func derivePhase(from vectors: [RepMotionVector]) -> RepMotionPhaseSignature? {
        let validVectors = vectors.filter { $0.values.count == RepMotionVector.dimensionCount }
        guard validVectors.isEmpty == false else { return nil }

        let initialMean = meanVector(for: validVectors)
        let initialStdDev = standardDeviationVector(for: validVectors, mean: initialMean)
        let filtered = validVectors.filter { vector in
            vector.values.indices.allSatisfy { index in
                let allowedDistance = max(
                    initialStdDev[index],
                    RepMotionTuning.minimumStandardDeviation
                ) * 2.0
                return abs(vector.values[index] - initialMean[index]) <= allowedDistance
            }
        }
        let finalVectors = filtered.isEmpty ? validVectors : filtered
        let finalMean = meanVector(for: finalVectors)
        let finalStdDev = standardDeviationVector(for: finalVectors, mean: finalMean)
            .map { max($0, RepMotionTuning.minimumStandardDeviation) }

        return RepMotionPhaseSignature(mean: finalMean, standardDeviation: finalStdDev)
    }

    private static func meanVector(for vectors: [RepMotionVector]) -> [Double] {
        var totals = Array(repeating: 0.0, count: RepMotionVector.dimensionCount)

        for vector in vectors {
            for index in totals.indices {
                totals[index] += vector.values[index]
            }
        }

        return totals.map { $0 / Double(vectors.count) }
    }

    private static func standardDeviationVector(for vectors: [RepMotionVector], mean: [Double]) -> [Double] {
        guard vectors.count > 1 else {
            return Array(repeating: RepMotionTuning.minimumStandardDeviation, count: RepMotionVector.dimensionCount)
        }

        var squaredTotals = Array(repeating: 0.0, count: RepMotionVector.dimensionCount)

        for vector in vectors {
            for index in squaredTotals.indices {
                let delta = vector.values[index] - mean[index]
                squaredTotals[index] += delta * delta
            }
        }

        return squaredTotals.map { sqrt($0 / Double(vectors.count)) }
    }
}

struct RepMotionSignature: Codable, Equatable {
    let phaseA: RepMotionPhaseSignature
    let phaseB: RepMotionPhaseSignature?
    let averagePhaseGap: Double?
    let averageRepDuration: Double?

    init(mean: [Double], standardDeviation: [Double]) {
        self.init(
            phaseA: RepMotionPhaseSignature(mean: mean, standardDeviation: standardDeviation)
        )
    }

    init(
        phaseA: RepMotionPhaseSignature,
        phaseB: RepMotionPhaseSignature? = nil,
        averagePhaseGap: Double? = nil,
        averageRepDuration: Double? = nil
    ) {
        self.phaseA = phaseA
        self.phaseB = phaseB
        self.averagePhaseGap = averagePhaseGap
        self.averageRepDuration = averageRepDuration
    }

    var mean: [Double] {
        phaseA.mean
    }

    var standardDeviation: [Double] {
        phaseA.standardDeviation
    }

    var isValid: Bool {
        phaseA.isValid && (phaseB?.isValid ?? true)
    }

    var supportsTwoPhaseCounting: Bool {
        phaseB?.isValid == true
    }

    func contains(_ vector: RepMotionVector, standardDeviationMultiplier: Double = 2.0) -> Bool {
        phaseA.contains(vector, standardDeviationMultiplier: standardDeviationMultiplier)
    }

    static func derive(from vectors: [RepMotionVector]) -> RepMotionSignature? {
        guard let phase = RepMotionPhaseSignature.derivePhase(from: vectors) else {
            return nil
        }
        return RepMotionSignature(phaseA: phase)
    }

    fileprivate static func derive(from pairs: [RepMotionPhasePair]) -> RepMotionSignature? {
        let validPairs = pairs.filter {
            $0.first.vector.values.count == RepMotionVector.dimensionCount
                && $0.second.vector.values.count == RepMotionVector.dimensionCount
        }
        guard validPairs.isEmpty == false,
              let phaseA = RepMotionPhaseSignature.derivePhase(from: validPairs.map(\.first.vector)),
              let phaseB = RepMotionPhaseSignature.derivePhase(from: validPairs.map(\.second.vector)) else {
            return nil
        }

        let phaseGaps = validPairs.map { $0.second.t - $0.first.t }
        let repDurations = zip(validPairs, validPairs.dropFirst()).map { previous, current in
            current.second.t - previous.second.t
        }

        return RepMotionSignature(
            phaseA: phaseA,
            phaseB: phaseB,
            averagePhaseGap: average(phaseGaps),
            averageRepDuration: average(repDurations)
        )
    }

    fileprivate func matchPhase(_ vector: RepMotionVector) -> RepPhaseMatch? {
        guard supportsTwoPhaseCounting, let phaseB else {
            return nil
        }

        return [
            phaseMatch(for: vector, phase: .phaseA, signature: phaseA),
            phaseMatch(for: vector, phase: .phaseB, signature: phaseB)
        ]
        .compactMap { $0 }
        .min { $0.score < $1.score }
    }

    private func phaseMatch(
        for vector: RepMotionVector,
        phase: RepMotionPhase,
        signature: RepMotionPhaseSignature
    ) -> RepPhaseMatch? {
        guard signature.contains(
            vector,
            standardDeviationMultiplier: RepMotionTuning.normalStandardDeviationMultiplier
        ) else {
            return nil
        }

        let directionSimilarity = signature.directionSimilarity(to: vector)
        guard directionSimilarity >= RepMotionTuning.normalDirectionSimilarity else {
            return nil
        }

        let referenceMagnitude = max(signature.referenceMagnitude, RepMotionTuning.minimumStandardDeviation)
        guard vector.motionMagnitude >= referenceMagnitude * RepMotionTuning.normalMagnitudeFraction else {
            return nil
        }

        let score = signature.normalizedDistance(to: vector) ?? .greatestFiniteMagnitude
        let highConfidence = signature.contains(
            vector,
            standardDeviationMultiplier: RepMotionTuning.highConfidenceStandardDeviationMultiplier
        )
            && directionSimilarity >= RepMotionTuning.highConfidenceDirectionSimilarity
            && vector.motionMagnitude >= referenceMagnitude * RepMotionTuning.highConfidenceMagnitudeFraction

        return RepPhaseMatch(
            phase: phase,
            highConfidence: highConfidence,
            score: score
        )
    }
}

final class RepCalibrationCollector {
    private let targetReps: Int
    private let peakFinder: RepMotionPeakFinder
    private var vectorizer = RepMotionVectorizer()
    private var pendingPhase: RepMotionPeakEvent?
    private var repPairs: [RepMotionPhasePair] = []

    init(
        targetReps: Int,
        threshold: Double,
        debounceSeconds: Double = 0.25,
        bufferSize: Int = 30,
        centerIdx: Int = 15
    ) {
        self.targetReps = targetReps
        self.peakFinder = RepMotionPeakFinder(
            threshold: threshold,
            debounceSeconds: debounceSeconds,
            bufferSize: bufferSize,
            centerIdx: centerIdx
        )
    }

    var repCount: Int {
        repPairs.count
    }

    func processSample(t: TimeInterval, userAcceleration: SIMD3<Double>) -> RepMotionSignature? {
        let vector = vectorizer.vector(for: userAcceleration)
        guard let peak = peakFinder.process(
            t: t,
            rawMagnitude: magnitude(of: userAcceleration),
            vector: vector
        ) else {
            return nil
        }

        processPeak(peak)

        guard repPairs.count >= targetReps else {
            return nil
        }

        return RepMotionSignature.derive(from: repPairs)
    }

    private func processPeak(_ peak: RepMotionPeakEvent) {
        guard let pendingPhase else {
            self.pendingPhase = peak
            return
        }

        let gap = peak.t - pendingPhase.t
        guard gap >= RepMotionTuning.minimumPhaseGapSeconds else {
            if peak.magnitude > pendingPhase.magnitude {
                self.pendingPhase = peak
            }
            return
        }

        guard gap <= RepMotionTuning.maximumPhaseGapSeconds else {
            self.pendingPhase = peak
            return
        }

        let directionSimilarity = directionalCosine(pendingPhase.vector.values, peak.vector.values)
        if directionSimilarity <= RepMotionTuning.calibrationOppositeDirectionSimilarity {
            repPairs.append(RepMotionPhasePair(first: pendingPhase, second: peak))
            self.pendingPhase = nil
        } else if peak.magnitude > pendingPhase.magnitude {
            self.pendingPhase = peak
        }
    }
}

protocol RepDetectorDelegate: AnyObject {
    func repCountDidChange(_ repCount: Int)
    func fatigueDetected()
}

class RepDetector {
    private let signature: RepMotionSignature?
    private let peakFinder: RepMotionPeakFinder

    private var vectorizer = RepMotionVectorizer()
    private var wasInsideSignature = false
    private var lastRepTime: TimeInterval = 0
    private var lastSampleTime: TimeInterval?
    private var pendingPhase: PendingRepPhaseEvent?
    private var lastCountedCompletionPhase: RepMotionPhase?
    private(set) var repCount: Int = 0
    private(set) var repIntervals: [Double] = []
    private(set) var baselineIOI: Double? = nil
    private(set) var lastTwoFatigued: (Bool, Bool) = (false, false)

    weak var delegate: RepDetectorDelegate?

    init(threshold: Double, signature: RepMotionSignature? = nil) {
        let activeSignature = signature?.isValid == true ? signature : nil
        self.signature = activeSignature
        self.peakFinder = RepMotionPeakFinder(
            threshold: threshold,
            debounceSeconds: activeSignature?.supportsTwoPhaseCounting == true
                ? RepMotionTuning.peakDebounceSeconds
                : RepMotionTuning.legacyDebounceSeconds,
            bufferSize: 30,
            centerIdx: 15
        )
    }

    func processSample(t: TimeInterval, userAcceleration: SIMD3<Double>) {
        lastSampleTime = t
        let vector = vectorizer.vector(for: userAcceleration)

        if let signature, signature.supportsTwoPhaseCounting {
            processTwoPhaseSignatureSample(
                t: t,
                rawMagnitude: magnitude(of: userAcceleration),
                vector: vector,
                signature: signature
            )
        } else if let signature {
            processLegacySignatureSample(t: t, vector: vector, signature: signature)
        } else {
            processThresholdSample(
                t: t,
                rawMagnitude: magnitude(of: userAcceleration),
                vector: vector
            )
        }
    }

    private func processTwoPhaseSignatureSample(
        t: TimeInterval,
        rawMagnitude: Double,
        vector: RepMotionVector,
        signature: RepMotionSignature
    ) {
        guard let peak = peakFinder.process(t: t, rawMagnitude: rawMagnitude, vector: vector) else {
            return
        }

        guard let match = signature.matchPhase(peak.vector) else {
            expirePendingPhase(at: peak.t)
            return
        }

        let currentPhase = PendingRepPhaseEvent(peak: peak, match: match)
        guard let pendingPhase else {
            self.pendingPhase = currentPhase
            return
        }

        let gap = peak.t - pendingPhase.peak.t
        guard gap >= RepMotionTuning.minimumPhaseGapSeconds else {
            if currentPhase.match.phase == pendingPhase.match.phase,
               currentPhase.match.score < pendingPhase.match.score {
                self.pendingPhase = currentPhase
            }
            return
        }

        guard gap <= RepMotionTuning.maximumPhaseGapSeconds else {
            self.pendingPhase = currentPhase
            return
        }

        guard currentPhase.match.phase != pendingPhase.match.phase else {
            if currentPhase.match.score < pendingPhase.match.score
                || currentPhase.peak.magnitude > pendingPhase.peak.magnitude {
                self.pendingPhase = currentPhase
            }
            return
        }

        countRep(at: peak.t)
        lastCountedCompletionPhase = currentPhase.match.phase
        self.pendingPhase = nil
    }

    private func processLegacySignatureSample(
        t: TimeInterval,
        vector: RepMotionVector,
        signature: RepMotionSignature
    ) {
        let isInsideSignature = signature.contains(vector)
        defer {
            wasInsideSignature = isInsideSignature
        }

        guard isInsideSignature, wasInsideSignature == false else {
            return
        }

        guard lastRepTime == 0 || t - lastRepTime > RepMotionTuning.legacyDebounceSeconds else {
            return
        }

        countRep(at: t)
    }

    private func processThresholdSample(
        t: TimeInterval,
        rawMagnitude: Double,
        vector: RepMotionVector
    ) {
        guard let peak = peakFinder.process(t: t, rawMagnitude: rawMagnitude, vector: vector) else {
            return
        }

        countRep(at: peak.t)
    }

    private func expirePendingPhase(at t: TimeInterval) {
        guard let pendingPhase,
              t - pendingPhase.peak.t > RepMotionTuning.maximumPhaseGapSeconds else {
            return
        }

        self.pendingPhase = nil
    }

    private func countRep(at t: TimeInterval) {
        repCount += 1

        if lastRepTime > 0 {
            let interval = t - lastRepTime
            repIntervals.append(interval)
            analyzeIOI(interval)
        }

        lastRepTime = t
        delegate?.repCountDidChange(repCount)
    }

    @discardableResult
    func finalizePendingRep() -> Int {
        guard signature?.supportsTwoPhaseCounting == true,
              let pendingPhase,
              repCount > 0,
              lastRepTime > 0 else {
            return repCount
        }

        let referenceTime = lastSampleTime ?? pendingPhase.peak.t
        guard referenceTime - pendingPhase.peak.t <= RepMotionTuning.finalPartialGraceSeconds,
              pendingPhase.peak.t - lastRepTime >= RepMotionTuning.minimumPhaseGapSeconds,
              pendingPhase.peak.t - lastRepTime <= RepMotionTuning.maximumPhaseGapSeconds,
              pendingPhase.match.highConfidence else {
            return repCount
        }

        if let lastCountedCompletionPhase,
           lastCountedCompletionPhase == pendingPhase.match.phase {
            return repCount
        }

        countRep(at: pendingPhase.peak.t)
        lastCountedCompletionPhase = pendingPhase.match.phase
        self.pendingPhase = nil
        return repCount
    }

    func reset() {
        vectorizer.reset()
        peakFinder.reset()
        wasInsideSignature = false
        lastRepTime = 0
        lastSampleTime = nil
        pendingPhase = nil
        lastCountedCompletionPhase = nil
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

private enum RepMotionPhase {
    case phaseA
    case phaseB
}

private struct RepPhaseMatch {
    let phase: RepMotionPhase
    let highConfidence: Bool
    let score: Double
}

private struct RepMotionPeakEvent {
    let t: TimeInterval
    let magnitude: Double
    let vector: RepMotionVector
}

private struct RepMotionPhasePair {
    let first: RepMotionPeakEvent
    let second: RepMotionPeakEvent
}

private struct PendingRepPhaseEvent {
    let peak: RepMotionPeakEvent
    let match: RepPhaseMatch
}

private final class RepMotionPeakFinder {
    private let threshold: Double
    private let debounceSeconds: Double
    private let bufferSize: Int
    private let centerIdx: Int
    private var sampleBuffer: [RepMotionPeakEvent] = []
    private var lastPeakTime: TimeInterval = 0

    init(
        threshold: Double,
        debounceSeconds: Double,
        bufferSize: Int,
        centerIdx: Int
    ) {
        self.threshold = threshold
        self.debounceSeconds = debounceSeconds
        self.bufferSize = bufferSize
        self.centerIdx = centerIdx
    }

    func process(
        t: TimeInterval,
        rawMagnitude: Double,
        vector: RepMotionVector
    ) -> RepMotionPeakEvent? {
        let sample = RepMotionPeakEvent(t: t, magnitude: rawMagnitude, vector: vector)
        sampleBuffer.append(sample)
        if sampleBuffer.count > bufferSize {
            sampleBuffer.removeFirst()
        }

        guard sampleBuffer.count == bufferSize else {
            return nil
        }

        let centerSample = sampleBuffer[centerIdx]
        guard centerSample.magnitude > threshold else {
            return nil
        }

        let windowMax = sampleBuffer.map(\.magnitude).max() ?? 0
        guard centerSample.magnitude >= windowMax else {
            return nil
        }

        guard lastPeakTime == 0 || centerSample.t - lastPeakTime > debounceSeconds else {
            return nil
        }

        lastPeakTime = centerSample.t
        return centerSample
    }

    func reset() {
        sampleBuffer.removeAll(keepingCapacity: true)
        lastPeakTime = 0
    }
}

private final class RepMotionVectorizer {
    private let smoothingWindowSize: Int
    private var accelerationWindow: [SIMD3<Double>] = []
    private var previousMagnitude: Double?

    init(smoothingWindowSize: Int = 3) {
        self.smoothingWindowSize = smoothingWindowSize
    }

    func vector(for userAcceleration: SIMD3<Double>) -> RepMotionVector {
        accelerationWindow.append(userAcceleration)
        if accelerationWindow.count > smoothingWindowSize {
            accelerationWindow.removeFirst()
        }

        let smoothed = accelerationWindow.reduce(SIMD3<Double>(repeating: 0)) { $0 + $1 } / Double(accelerationWindow.count)
        let mag = magnitude(of: smoothed)
        let deltaMagnitude = mag - (previousMagnitude ?? mag)
        previousMagnitude = mag

        return RepMotionVector(values: [
            smoothed.x,
            smoothed.y,
            smoothed.z,
            mag,
            deltaMagnitude
        ])
    }

    func reset() {
        accelerationWindow.removeAll(keepingCapacity: true)
        previousMagnitude = nil
    }
}

private func average(_ values: [Double]) -> Double? {
    guard values.isEmpty == false else { return nil }
    return values.reduce(0, +) / Double(values.count)
}

private func magnitude(of vector: SIMD3<Double>) -> Double {
    sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
}

private func directionalMagnitude(_ values: [Double]) -> Double {
    guard values.count >= 3 else { return 0 }
    return sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2])
}

private func directionalCosine(_ lhs: [Double], _ rhs: [Double]) -> Double {
    guard lhs.count >= 3, rhs.count >= 3 else { return 0 }

    let dotProduct = lhs[0] * rhs[0] + lhs[1] * rhs[1] + lhs[2] * rhs[2]
    let lhsMagnitude = directionalMagnitude(lhs)
    let rhsMagnitude = directionalMagnitude(rhs)
    let denominator = lhsMagnitude * rhsMagnitude

    guard denominator > 0.0001 else { return 0 }
    return dotProduct / denominator
}
