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
            error = nil
            Task {
                await refreshSpools()
            }
        } catch {
            self.error = error
        }
    }

    func update(_ spool: Spool) {
        do {
            try implementation.update(spool)
            error = nil
            Task {
                await refreshSpools()
            }
        } catch {
            self.error = error
        }
    }

    func delete(_ spool: Spool) {
        do {
            try implementation.delete(spool)
            error = nil
            Task {
                await refreshSpools()
            }
        } catch {
            self.error = error
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            delete(spools[index])
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
