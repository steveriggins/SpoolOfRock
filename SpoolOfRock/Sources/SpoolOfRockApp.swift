import SwiftUI
import SwiftData

@main
struct SpoolOfRockApp: App {
    let modelContainer: ModelContainer
    let spoolRepository: SpoolRepository

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

            // Create repository with SwiftData implementation
            let implementation = SwiftDataSpoolRepository(
                modelContext: modelContainer.mainContext
            )
            spoolRepository = SpoolRepository(implementation: implementation)

        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .spoolRepository(spoolRepository)
        }
        .modelContainer(modelContainer)
    }
}
