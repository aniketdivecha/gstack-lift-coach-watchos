import WatchKit
import SwiftData

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var modelContainer: ModelContainer!

    func applicationDidFinishLaunching() {
        do {
            modelContainer = try ModelContainer(
                for: ExerciseRecord.self, RestRecord.self, ExerciseCalibration.self
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
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
