import Foundation

/// In-memory implementation of SpoolRepositoryProtocol for testing
@MainActor
final class InMemorySpoolRepository: SpoolRepositoryProtocol {
    private(set) var spools: [Spool]

    init(initialSpools: [Spool] = []) {
        self.spools = initialSpools.sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ spool: Spool) throws {
        spools.append(spool)
        spools.sort { $0.createdAt > $1.createdAt }
    }

    func update(_ spool: Spool) throws {
        guard let index = spools.firstIndex(where: { $0.id == spool.id }) else {
            throw RepositoryError.spoolNotFound
        }
        spools[index] = spool
    }

    func delete(_ spool: Spool) throws {
        spools.removeAll { $0.id == spool.id }
    }

    func fetchAll() async throws -> [Spool] {
        return spools
    }

    func findByNFCTag(_ tagID: String) async throws -> Spool? {
        return spools.first { $0.nfcTagIdentifier == tagID }
    }
}

enum RepositoryError: Error {
    case spoolNotFound
}
