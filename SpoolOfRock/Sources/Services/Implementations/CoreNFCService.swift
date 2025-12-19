import Foundation
import CoreNFC

@MainActor
final class CoreNFCService: NSObject, NFCServiceProtocol {
    private var readSession: NFCNDEFReaderSession?
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

            let session = NFCNDEFReaderSession(
                delegate: self,
                queue: nil,
                invalidateAfterFirstRead: true
            )
            session.alertMessage = "Hold your iPhone near the NFC tag"
            session.begin()
            self.readSession = session
        }
    }

    func writeTag(spoolID: UUID) async throws {
        guard isNFCAvailable else {
            throw NFCError.notSupported
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.writeContinuation = continuation
            self.spoolIDToWrite = spoolID

            let session = NFCTagReaderSession(
                pollingOption: .iso14443,
                delegate: self,
                queue: nil
            )
            session?.alertMessage = "Hold your iPhone near the NFC tag to write"
            session?.begin()
            self.writeSession = session
        }
    }

    func startBackgroundReading(onTagDetected: @escaping (UUID) -> Void) {
        guard isNFCAvailable else { return }
        self.backgroundTagHandler = onTagDetected
    }

    func stopBackgroundReading() {
        self.backgroundTagHandler = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension CoreNFCService: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        Task { @MainActor in
            guard let message = messages.first,
                  let record = message.records.first else {
                readContinuation?.resume(throwing: NFCError.invalidData)
                readContinuation = nil
                return
            }

            // Extract UUID from payload (skipping the first 3 bytes which are NDEF text header)
            let payloadData = record.payload
            guard payloadData.count > 3 else {
                readContinuation?.resume(throwing: NFCError.invalidData)
                readContinuation = nil
                return
            }

            let uuidData = payloadData.advanced(by: 3)
            guard let uuidString = String(data: uuidData, encoding: .utf8),
                  let uuid = UUID(uuidString: uuidString) else {
                readContinuation?.resume(throwing: NFCError.invalidData)
                readContinuation = nil
                return
            }

            session.alertMessage = "Tag read successfully"
            session.invalidate()

            // Handle background reading if registered
            if let handler = backgroundTagHandler {
                handler(uuid)
            }

            readContinuation?.resume(returning: uuid)
            readContinuation = nil
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
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
                    writeContinuation?.resume(throwing: NFCError.writingFailed("Incompatible tag"))
                    writeContinuation = nil
                    return
                }

                // Query NDEF status - returns (NFCNDEFStatus, Int)
                let (status, _) = try await miFareTag.queryNDEFStatus()

                guard status != .notSupported else {
                    session.alertMessage = "Tag doesn't support NDEF"
                    session.invalidate()
                    writeContinuation?.resume(throwing: NFCError.writingFailed("Tag doesn't support NDEF"))
                    writeContinuation = nil
                    return
                }

                guard let spoolID = spoolIDToWrite else {
                    session.alertMessage = "No data to write"
                    session.invalidate()
                    writeContinuation?.resume(throwing: NFCError.writingFailed("No data to write"))
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
                    writeContinuation?.resume(throwing: NFCError.writingFailed("Failed to create payload"))
                    writeContinuation = nil
                    return
                }

                let message = NFCNDEFMessage(records: [payload])

                // Write NDEF message to tag
                try await miFareTag.writeNDEF(message)

                session.alertMessage = "Tag written successfully"
                session.invalidate()

                writeContinuation?.resume()
                writeContinuation = nil
                spoolIDToWrite = nil

            } catch {
                Task { @MainActor in
                    session.alertMessage = "Write failed: \(error.localizedDescription)"
                    session.invalidate()
                    writeContinuation?.resume(throwing: NFCError.writingFailed(error.localizedDescription))
                    writeContinuation = nil
                    spoolIDToWrite = nil
                }
            }
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            if let continuation = writeContinuation {
                let nfcError = error as? NFCReaderError
                if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
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
