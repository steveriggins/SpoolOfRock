import Foundation

/// Mock NFC service for simulator and devices without NFC support
@MainActor
final class MockNFCService: NFCServiceProtocol {
    var isNFCAvailable: Bool { false }

    func readTag() async throws -> UUID {
        throw NFCError.notSupported
    }

    func writeTag(spoolID: UUID) async throws {
        throw NFCError.notSupported
    }
}
