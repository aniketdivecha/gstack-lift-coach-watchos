import SwiftData
import Foundation

@Model
class ExerciseCalibration {
    var id: String?
    var exerciseId: String
    var calibratedWeight: Double
    var calibrationDate: Date
    var detectionThreshold: Double
    var manualEntry: Bool
    var motionSignatureMean: Data?
    var motionSignatureStandardDeviation: Data?
    var motionSignatureData: Data?

    init(
        id: String? = nil,
        exerciseId: String,
        calibratedWeight: Double,
        calibrationDate: Date = Date(),
        detectionThreshold: Double,
        manualEntry: Bool = false,
        motionSignature: RepMotionSignature? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.calibratedWeight = calibratedWeight
        self.calibrationDate = calibrationDate
        self.detectionThreshold = detectionThreshold
        self.manualEntry = manualEntry
        self.motionSignatureMean = Self.encodeVector(motionSignature?.mean)
        self.motionSignatureStandardDeviation = Self.encodeVector(motionSignature?.standardDeviation)
        self.motionSignatureData = Self.encodeSignature(motionSignature)
    }

    var motionSignature: RepMotionSignature? {
        if let signature = Self.decodeSignature(motionSignatureData),
           signature.isValid {
            return signature
        }

        guard let mean = Self.decodeVector(motionSignatureMean),
              let standardDeviation = Self.decodeVector(motionSignatureStandardDeviation) else {
            return nil
        }

        let signature = RepMotionSignature(mean: mean, standardDeviation: standardDeviation)
        return signature.isValid ? signature : nil
    }

    private static func encodeVector(_ values: [Double]?) -> Data? {
        guard let values else { return nil }
        return try? JSONEncoder().encode(values)
    }

    private static func decodeVector(_ data: Data?) -> [Double]? {
        guard let data else { return nil }
        return try? JSONDecoder().decode([Double].self, from: data)
    }

    private static func encodeSignature(_ signature: RepMotionSignature?) -> Data? {
        guard let signature else { return nil }
        return try? JSONEncoder().encode(signature)
    }

    private static func decodeSignature(_ data: Data?) -> RepMotionSignature? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(RepMotionSignature.self, from: data)
    }
}
