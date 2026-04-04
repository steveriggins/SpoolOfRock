import Foundation
import CoreNFC
import CryptoKit

@MainActor
final class CoreNFCService: NSObject, NFCServiceProtocol {
    private var readSession: NFCNDEFReaderSession?
    private var tagReadSession: NFCTagReaderSession?
    private var writeSession: NFCTagReaderSession?
    private var readContinuation: CheckedContinuation<UUID, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var backgroundTagHandler: ((UUID) -> Void)?
    private var spoolIDToWrite: UUID?

    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    func readTag() async throws -> UUID {
        guard isNFCAvailable else {
            throw NFCError.notSupported
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.readContinuation = continuation

            // Stop any existing sessions before starting explicit read
            if let existingSession = readSession {
                existingSession.invalidate()
                readSession = nil
            }
            if let existingSession = tagReadSession {
                existingSession.invalidate()
                tagReadSession = nil
            }
            backgroundTagHandler = nil

            let configuration = NFCTagReaderSession.Configuration(pollingOption: .iso14443)
            let session = NFCTagReaderSession(
                configuration: configuration,
                delegate: self
            )
            session.alertMessage = "Hold your iPhone near the NFC tag"
            session.begin()
            self.tagReadSession = session
        }
    }

    func writeTag(spoolID: UUID) async throws {
        guard isNFCAvailable else {
            throw NFCError.notSupported
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.writeContinuation = continuation
            self.spoolIDToWrite = spoolID

            // Stop any existing read session before starting write
            if let existingSession = readSession {
                existingSession.invalidate()
                readSession = nil
            }
            backgroundTagHandler = nil

            let configuration = NFCTagReaderSession.Configuration(pollingOption: .iso14443)
            let session = NFCTagReaderSession(
                configuration: configuration,
                delegate: self
            )
            session.alertMessage = "Hold your iPhone near the NFC tag to write"
            session.begin()
            self.writeSession = session
        }
    }

    func startBackgroundReading(onTagDetected: @escaping (UUID) -> Void) {
        guard isNFCAvailable else { return }
        self.backgroundTagHandler = onTagDetected

        // Start a persistent NDEF reader session for background scanning
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false  // Keep session active for continuous scanning
        )
        session.alertMessage = "Ready to scan. Hold iPhone near NFC tag."
        session.begin()
        self.readSession = session
    }

    func stopBackgroundReading() {
        self.backgroundTagHandler = nil
        readSession?.invalidate()
        readSession = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension CoreNFCService: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session became active - required delegate method for background reading
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        Task { @MainActor in
            guard let message = messages.first,
                  let record = message.records.first else {
                if let continuation = readContinuation {
                    continuation.resume(throwing: NFCError.invalidData)
                    readContinuation = nil
                }
                return
            }

            // Extract UUID from payload
            let payloadData = record.payload
            guard payloadData.count > 3 else {
                if let continuation = readContinuation {
                    continuation.resume(throwing: NFCError.invalidData)
                    readContinuation = nil
                }
                return
            }

            // Check the status byte to determine language code length
            let statusByte = payloadData[0]
            let languageCodeLength = Int(statusByte & 0x3F) // Lower 6 bits
            let headerLength = 1 + languageCodeLength // status byte + language code

            guard payloadData.count > headerLength else {
                if let continuation = readContinuation {
                    continuation.resume(throwing: NFCError.invalidData)
                    readContinuation = nil
                }
                return
            }

            let uuidData = payloadData.advanced(by: headerLength)

            // Try UTF-16 first (Apple's wellKnownTypeTextPayload may encode as UTF-16), then UTF-8
            var uuidString: String?
            if uuidData.count >= 2 && uuidData[0] == 0xFF && uuidData[1] == 0xFE {
                // UTF-16 Little Endian (has BOM)
                uuidString = String(data: uuidData, encoding: .utf16LittleEndian)
            } else if uuidData.count >= 2 && uuidData[0] == 0xFE && uuidData[1] == 0xFF {
                // UTF-16 Big Endian (has BOM)
                uuidString = String(data: uuidData, encoding: .utf16BigEndian)
            } else {
                // Try UTF-8
                uuidString = String(data: uuidData, encoding: .utf8)
            }

            guard var uuidString = uuidString else {
                if let continuation = readContinuation {
                    continuation.resume(throwing: NFCError.invalidData)
                    readContinuation = nil
                }
                return
            }

            // Remove BOM character if present (U+FEFF)
            uuidString = uuidString.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))

            guard let uuid = UUID(uuidString: uuidString) else {
                if let continuation = readContinuation {
                    continuation.resume(throwing: NFCError.invalidData)
                    readContinuation = nil
                }
                return
            }

            // If this is an explicit read (not background), complete the continuation
            if let continuation = readContinuation {
                session.alertMessage = "Tag read successfully"
                session.invalidate()
                continuation.resume(returning: uuid)
                readContinuation = nil
            }
            // If this is background reading, call the handler and keep scanning
            else if let handler = backgroundTagHandler {
                session.alertMessage = "Tag detected"
                handler(uuid)
            }
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            // Handle explicit read continuation
            if let continuation = readContinuation {
                let nfcError = error as? NFCReaderError
                if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
                    continuation.resume(throwing: NFCError.userCancelled)
                } else if nfcError?.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                    // Session invalidated after successful read - this is expected
                    return
                } else {
                    continuation.resume(throwing: NFCError.readingFailed(error.localizedDescription))
                }
                readContinuation = nil
            }
            // Handle background reading session invalidation
            else if backgroundTagHandler != nil {
                let nfcError = error as? NFCReaderError
                // If user cancelled background scanning, clean up
                if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
                    backgroundTagHandler = nil
                    readSession = nil
                }
                // For other errors during background reading, also clean up
                else if nfcError?.code != .readerSessionInvalidationErrorFirstNDEFTagRead {
                    backgroundTagHandler = nil
                    readSession = nil
                }
            }
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate (for writing)
extension CoreNFCService: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session became active - required delegate method
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        Task { @MainActor in
            do {
                try await session.connect(to: tag)

                guard case .miFare(let miFareTag) = tag else {
                    session.alertMessage = "Incompatible tag type"
                    session.invalidate()

                    if let continuation = readContinuation {
                        continuation.resume(throwing: NFCError.readingFailed("Incompatible tag"))
                        readContinuation = nil
                    }
                    if let continuation = writeContinuation {
                        continuation.resume(throwing: NFCError.writingFailed("Incompatible tag"))
                        writeContinuation = nil
                    }
                    return
                }

                // If this is a read operation, just get the tag identifier
                if let continuation = readContinuation {
                    // Convert tag identifier to UUID using deterministic hashing
                    let tagID = miFareTag.identifier
                    let uuid = UUID(data: tagID)

                    session.alertMessage = "Tag read successfully"
                    session.invalidate()
                    continuation.resume(returning: uuid)
                    readContinuation = nil
                    return
                }

                // If this is a write operation, proceed with writing
                if let continuation = writeContinuation {
                    // Query NDEF status - returns (NFCNDEFStatus, Int)
                    let (status, _) = try await miFareTag.queryNDEFStatus()

                    guard status != .notSupported else {
                        session.alertMessage = "Tag doesn't support NDEF"
                        session.invalidate()
                        continuation.resume(throwing: NFCError.writingFailed("Tag doesn't support NDEF"))
                        writeContinuation = nil
                        return
                    }

                    guard let spoolID = spoolIDToWrite else {
                        session.alertMessage = "No data to write"
                        session.invalidate()
                        continuation.resume(throwing: NFCError.writingFailed("No data to write"))
                        writeContinuation = nil
                        return
                    }

                    // Create NDEF message with spool UUID
                    let uuidString = spoolID.uuidString
                    let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
                        string: uuidString,
                        locale: Locale(identifier: "en")
                    )

                    guard let payload = payload else {
                        session.alertMessage = "Failed to create payload"
                        session.invalidate()
                        continuation.resume(throwing: NFCError.writingFailed("Failed to create payload"))
                        writeContinuation = nil
                        return
                    }

                    let message = NFCNDEFMessage(records: [payload])

                    // Write NDEF message to tag
                    try await miFareTag.writeNDEF(message)

                    session.alertMessage = "Tag written successfully"
                    session.invalidate()

                    continuation.resume()
                    writeContinuation = nil
                    spoolIDToWrite = nil
                }

            } catch {
                Task { @MainActor in
                    session.alertMessage = "Failed: \(error.localizedDescription)"
                    session.invalidate()

                    if let continuation = readContinuation {
                        continuation.resume(throwing: NFCError.readingFailed(error.localizedDescription))
                        readContinuation = nil
                    }
                    if let continuation = writeContinuation {
                        continuation.resume(throwing: NFCError.writingFailed(error.localizedDescription))
                        writeContinuation = nil
                        spoolIDToWrite = nil
                    }
                }
            }
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            let nfcError = error as? NFCReaderError
            let userCancelled = nfcError?.code == .readerSessionInvalidationErrorUserCanceled

            if let continuation = readContinuation {
                if userCancelled {
                    continuation.resume(throwing: NFCError.userCancelled)
                } else {
                    continuation.resume(throwing: NFCError.readingFailed(error.localizedDescription))
                }
                readContinuation = nil
            }

            if let continuation = writeContinuation {
                if userCancelled {
                    continuation.resume(throwing: NFCError.userCancelled)
                } else {
                    continuation.resume(throwing: NFCError.writingFailed(error.localizedDescription))
                }
                writeContinuation = nil
                spoolIDToWrite = nil
            }
        }
    }
}

// MARK: - UUID Extension for NFC Tag Identifiers
extension UUID {
    /// Creates a deterministic UUID from NFC tag identifier data
    init(data: Data) {
        // Hash the tag identifier to create a deterministic UUID
        let hash = SHA256.hash(data: data)
        let hashData = Data(hash)

        // Take first 16 bytes of hash and convert to UUID
        let uuidBytes = Array(hashData.prefix(16))
        let uuidString = String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                               uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                               uuidBytes[4], uuidBytes[5],
                               uuidBytes[6], uuidBytes[7],
                               uuidBytes[8], uuidBytes[9],
                               uuidBytes[10], uuidBytes[11], uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15])

        self.init(uuidString: uuidString)!
    }
}
