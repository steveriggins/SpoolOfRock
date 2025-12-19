import SwiftUI
import SwiftData

@main
struct SpoolOfRockApp: App {
    let modelContainer: ModelContainer
    let spoolRepository: SpoolRepository
    let nfcManager: NFCManager

    init() {
        do {
            // Schema with models - SwiftData handles lightweight migration automatically
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

            // Create NFC service based on environment
            #if targetEnvironment(simulator)
            let nfcService: NFCServiceProtocol = MockNFCService()
            #else
            let nfcService: NFCServiceProtocol = CoreNFCService()
            #endif

            nfcManager = NFCManager(service: nfcService, repository: spoolRepository)

        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .spoolRepository(spoolRepository)
                .nfcManager(nfcManager)
        }
        .modelContainer(modelContainer)
    }
}
