import Foundation
import SwiftData

/// SwiftData implementation of SpoolRepositoryProtocol
@MainActor
final class SwiftDataSpoolRepository: SpoolRepositoryProtocol {
    private let modelContext: ModelContext
    private(set) var spools: [Spool] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ spool: Spool) throws {
        modelContext.insert(spool)
        try modelContext.save()
        Task {
            try? await refreshSpools()
        }
    }

    func update(_ spool: Spool) throws {
        // SwiftData tracks changes automatically
        try modelContext.save()
        Task {
            try? await refreshSpools()
        }
    }

    func delete(_ spool: Spool) throws {
        modelContext.delete(spool)
        try modelContext.save()
        Task {
            try? await refreshSpools()
        }
    }

    func fetchAll() async throws -> [Spool] {
        let descriptor = FetchDescriptor<Spool>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func findByNFCTag(_ tagID: String) async throws -> Spool? {
        var descriptor = FetchDescriptor<Spool>(
            predicate: #Predicate { spool in
                spool.nfcTagIdentifier == tagID
            }
        )
        descriptor.fetchLimit = 1
        let results = try modelContext.fetch(descriptor)
        return results.first
    }

    private func refreshSpools() async throws {
        spools = try await fetchAll()
    }
}
