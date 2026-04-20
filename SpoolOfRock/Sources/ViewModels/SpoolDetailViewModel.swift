import Foundation
import Observation

/// ViewModel for SpoolDetailView handling spool updates
@Observable
@MainActor
final class SpoolDetailViewModel {
    var currentWeight: Double
    private(set) var isDeleted = false

    let spool: Spool
    private let repository: SpoolRepository

    var manufacturer: String { spool.manufacturer }
    var type: FilamentType { spool.type }
    var color: String { spool.color }
    var originalWeight: Double { spool.originalWeight }

    var remainingPercentage: Double {
        guard originalWeight > 0 else { return 0 }
        return (currentWeight / originalWeight) * 100
    }

    init(spool: Spool, repository: SpoolRepository) {
        self.spool = spool
        self.repository = repository
        self.currentWeight = spool.currentWeight
    }

    func save() {
        guard !isDeleted else { return }
        spool.currentWeight = currentWeight
        repository.update(spool)
    }

    func deleteSpool() {
        repository.delete(spool)
        isDeleted = true
    }
}
