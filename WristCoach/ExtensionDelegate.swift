import WatchKit
import SwiftData

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var modelContainer: ModelContainer!

    func applicationDidFinishLaunching() {
        let schema = ModelSchema([
            ExerciseRecord.self,
            RestRecord.self,
            ExerciseCalibration.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
    }

    func applicationDidBecomeActive() {
        // Handle app becoming active
    }

    func applicationWillResignActive() {
        // Handle app resigning active
    }

    func handleBackgroundTasks() {
        // Handle background tasks
    }
}
