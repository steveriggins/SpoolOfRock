import Foundation
import Observation

/// Observable repository wrapper for spool data access
@Observable
@MainActor
final class SpoolRepository {
    var spools: [Spool] = []
    var error: Error?

    private let implementation: SpoolRepositoryProtocol

    init(implementation: SpoolRepositoryProtocol) {
        self.implementation = implementation
        Task {
            await refreshSpools()
        }
    }

    func add(_ spool: Spool) {
        do {
            try implementation.add(spool)
            spools = implementation.spools
            error = nil
        } catch {
            self.error = error
        }
    }

    func update(_ spool: Spool) {
        do {
            try implementation.update(spool)
            spools = implementation.spools
            error = nil
        } catch {
            self.error = error
        }
    }

    func delete(_ spool: Spool) {
        do {
            try implementation.delete(spool)
            spools = implementation.spools
            error = nil
        } catch {
            self.error = error
        }
    }

    func delete(at offsets: IndexSet) {
        do {
            let spoolsToDelete = offsets.map { spools[$0] }
            for spool in spoolsToDelete {
                try implementation.delete(spool)
            }
            spools = implementation.spools
            error = nil
        } catch {
            self.error = error
        }
    }

    private func refreshSpools() async {
        do {
            spools = try await implementation.fetchAll()
        } catch {
            self.error = error
        }
    }
}
