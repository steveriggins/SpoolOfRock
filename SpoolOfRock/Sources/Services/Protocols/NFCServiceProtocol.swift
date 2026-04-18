import Foundation

enum NFCError: LocalizedError {
    case notSupported
    case readingFailed(String)
    case writingFailed(String)
    case invalidData
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "NFC is not supported on this device"
        case .readingFailed(let message):
            return "Failed to read NFC tag: \(message)"
        case .writingFailed(let message):
            return "Failed to write NFC tag: \(message)"
        case .invalidData:
            return "Invalid NFC tag data"
        case .userCancelled:
            return "NFC operation cancelled"
        }
    }
}

@MainActor
protocol NFCServiceProtocol {
    /// Check if NFC is available on this device
    var isNFCAvailable: Bool { get }

    /// Read an NFC tag and return the spool UUID stored on it
    func readTag() async throws -> UUID

    /// Write a spool UUID to an NFC tag
    func writeTag(spoolID: UUID) async throws
}
