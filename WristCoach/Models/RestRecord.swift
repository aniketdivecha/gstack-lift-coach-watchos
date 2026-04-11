import SwiftData
import Foundation

@Model
class RestRecord {
    var id: String?
    var exerciseId: String
    var date: Date
    var restDurationSeconds: Double
    var startHR: Double
    var endHR: Double
    var userOverrode: Bool

    init(
        id: String? = nil,
        exerciseId: String,
        date: Date = Date(),
        restDurationSeconds: Double,
        startHR: Double = 0,
        endHR: Double = 0,
        userOverrode: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.date = date
        self.restDurationSeconds = restDurationSeconds
        self.startHR = startHR
        self.endHR = endHR
        self.userOverrode = userOverrode
    }
}
