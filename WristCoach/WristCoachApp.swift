import SwiftUI
import SwiftData

@main
struct WristCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ExerciseRecord.self, RestRecord.self, ExerciseCalibration.self])
        }
    }
}

#Preview {
    WristCoachApp()
}
