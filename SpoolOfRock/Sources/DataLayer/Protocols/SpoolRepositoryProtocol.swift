import Foundation

/// Protocol defining the contract for spool data persistence
@MainActor
protocol SpoolRepositoryProtocol {
    /// Current list of spools sorted by creation date (newest first)
    var spools: [Spool] { get }

    /// Add a new spool to the repository
    func add(_ spool: Spool) throws

    /// Update an existing spool
    func update(_ spool: Spool) throws

    /// Delete a spool from the repository
    func delete(_ spool: Spool) throws

    /// Fetch all spools from the data source
    func fetchAll() async throws -> [Spool]

    /// Find spool by NFC tag identifier
    func findByNFCTag(_ tagID: String) async throws -> Spool?
}
