import SwiftUI
import SwiftData

@main
struct SpoolOfRockApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Spool.self,
            ])

            #if targetEnvironment(simulator)
            // For simulator: use local storage without CloudKit syncing
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            #else
            // For real devices: enable CloudKit syncing
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            #endif

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
