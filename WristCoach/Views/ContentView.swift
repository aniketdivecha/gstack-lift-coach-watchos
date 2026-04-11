import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MusclePickerView(onSelectGroup: { _ in })
                .tabItem {
                    Label("Picker", systemImage: "dumbbell")
                }

            ExerciseQueueView(exercises: [], onBegin: {}, onSelectExercise: { _ in })
                .tabItem {
                    Label("Queue", systemImage: "list.bullet")
                }

            CalibrationView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onComplete: { _ in }, onManualEntry: {})
                .tabItem {
                    Label("Calibrate", systemImage: "slider.horizontal.3")
                }

            ActiveSetView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), targetReps: 8, onRepCountUpdate: { _, _, _ in }, onStop: {})
                .tabItem {
                    Label("Workout", systemImage: "play.circle")
                }

            RestView(exercise: Exercise(id: "bench_press", name: "Bench Press", muscleGroups: ["chest"], defaultThreshold: 0.4, increment: Exercise.Increments(small: 2.5, large: 5.0), isBodyweight: false, isIsometric: false, weightType: .free, minimumWeight: 2.5, defaultStartingWeight: 45.0), onNext: {})
                .tabItem {
                    Label("Rest", systemImage: "heart.circle")
                }

            SessionSummaryView(exercises: [], records: [], onDone: {})
                .tabItem {
                    Label("Summary", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}
