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

    init(
        id: String? = nil,
        exerciseId: String,
        calibratedWeight: Double,
        calibrationDate: Date = Date(),
        detectionThreshold: Double,
        manualEntry: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.calibratedWeight = calibratedWeight
        self.calibrationDate = calibrationDate
        self.detectionThreshold = detectionThreshold
        self.manualEntry = manualEntry
    }
}
