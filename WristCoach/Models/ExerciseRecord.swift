import SwiftData
import Foundation

@Model
class ExerciseRecord {
    var id: String?
    var exerciseId: String
    var exerciseName: String?
    var date: Date
    var targetWeight: Double
    var targetReps: Int
    var actualReps: Int
    var repIntervals: [Double]
    var struggled: Bool
    var manualOverride: Bool
    var degradedHR: Bool

    init(
        id: String? = nil,
        exerciseId: String,
        exerciseName: String = "",
        date: Date = Date(),
        targetWeight: Double,
        targetReps: Int,
        actualReps: Int,
        repIntervals: [Double] = [],
        struggled: Bool = false,
        manualOverride: Bool = false,
        degradedHR: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.date = date
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.repIntervals = repIntervals
        self.struggled = struggled
        self.manualOverride = manualOverride
        self.degradedHR = degradedHR
    }
}
