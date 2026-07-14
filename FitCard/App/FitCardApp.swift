import SwiftUI
import SwiftData

@main
struct FitCardApp: App {
    init() {
        TabBarStyling.apply()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .onAppear {
                    ModelContainer.normalizeRoutineDefaultsIfNeeded()
                    ModelContainer.seedSampleDataIfNeeded()
                }
        }
        .modelContainer(ModelContainer.shared)
    }
}
