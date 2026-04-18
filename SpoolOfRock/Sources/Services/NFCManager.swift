import Foundation
import Observation

/// Observable NFC manager that coordinates NFC operations
@Observable
@MainActor
final class NFCManager {
    private let service: NFCServiceProtocol
    private let repository: SpoolRepository

    var isNFCAvailable: Bool { service.isNFCAvailable }
    var error: NFCError?
    var isReading = false
    var isWriting = false

    init(service: NFCServiceProtocol, repository: SpoolRepository) {
        self.service = service
        self.repository = repository
    }

    /// Read tag and return the UUID from it
    func readTag() async -> UUID? {
        guard isNFCAvailable else {
            error = .notSupported
            return nil
        }

        isReading = true
        defer { isReading = false }

        do {
            let tagID = try await service.readTag()
            error = nil
            return tagID
        } catch let nfcError as NFCError {
            if case .userCancelled = nfcError {
                // Don't set error for user cancellation
                error = nil
            } else {
                error = nfcError
            }
            return nil
        } catch {
            self.error = .readingFailed(error.localizedDescription)
            return nil
        }
    }

    /// Read tag and find associated spool
    func readTagAndFindSpool() async -> Spool? {
        guard let tagID = await readTag() else {
            return nil
        }

        return findSpool(for: tagID)
    }

    func findSpool(for tagID: UUID) -> Spool? {
        repository.spools.first {
            $0.id == tagID || $0.nfcTagIdentifier == tagID.uuidString
        }
    }

    /// Write spool ID to tag and update spool record
    func writeTagForSpool(_ spool: Spool) async -> Bool {
        guard isNFCAvailable else {
            error = .notSupported
            return false
        }

        isWriting = true
        defer { isWriting = false }

        do {
            try await service.writeTag(spoolID: spool.id)
            // Keep this for backward compatibility with existing data and lookups.
            spool.nfcTagIdentifier = spool.id.uuidString
            repository.update(spool)
            error = nil
            return true
        } catch let nfcError as NFCError {
            if case .userCancelled = nfcError {
                // Don't set error for user cancellation
                error = nil
            } else {
                error = nfcError
            }
            return false
        } catch {
            self.error = .writingFailed(error.localizedDescription)
            return false
        }
    }

    /// Remove tag association from spool
    func removeTagFromSpool(_ spool: Spool) {
        spool.nfcTagIdentifier = nil
        repository.update(spool)
    }

    /// Clear error state
    func clearError() {
        error = nil
    }
}
