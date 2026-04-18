import Foundation
import CoreNFC

@MainActor
final class CoreNFCService: NSObject, NFCServiceProtocol {
    private var tagReadSession: NFCTagReaderSession?
    private var writeSession: NFCTagReaderSession?
    private var readContinuation: CheckedContinuation<UUID, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
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

            if let existingSession = tagReadSession {
                existingSession.invalidate()
                tagReadSession = nil
            }

            if let existingSession = writeSession {
                existingSession.invalidate()
                writeSession = nil
            }

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

            if let existingSession = tagReadSession {
                existingSession.invalidate()
                tagReadSession = nil
            }

            if let existingSession = writeSession {
                existingSession.invalidate()
                writeSession = nil
            }

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

    private func parseUUIDFromTextPayload(_ payloadData: Data) -> UUID? {
        guard payloadData.count > 3 else {
            return nil
        }

        // Text payload format: status byte + language code + content.
        let statusByte = payloadData[0]
        let languageCodeLength = Int(statusByte & 0x3F)
        let headerLength = 1 + languageCodeLength

        guard payloadData.count > headerLength else {
            return nil
        }

        let uuidData = payloadData.advanced(by: headerLength)

        let uuidString: String?
        if uuidData.count >= 2 && uuidData[0] == 0xFF && uuidData[1] == 0xFE {
            uuidString = String(data: uuidData, encoding: .utf16LittleEndian)
        } else if uuidData.count >= 2 && uuidData[0] == 0xFE && uuidData[1] == 0xFF {
            uuidString = String(data: uuidData, encoding: .utf16BigEndian)
        } else {
            uuidString = String(data: uuidData, encoding: .utf8)
        }

        guard var uuidString else {
            return nil
        }

        uuidString = uuidString.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
        return UUID(uuidString: uuidString)
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension CoreNFCService: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Required delegate method.
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        Task { @MainActor in
            do {
                try await session.connect(to: tag)

                guard case .miFare(let miFareTag) = tag else {
                    let readContinuation = readContinuation
                    let writeContinuation = writeContinuation
                    self.readContinuation = nil
                    self.writeContinuation = nil
                    self.tagReadSession = nil
                    self.writeSession = nil
                    self.spoolIDToWrite = nil

                    session.alertMessage = "Incompatible tag type"
                    session.invalidate()

                    readContinuation?.resume(throwing: NFCError.readingFailed("Incompatible tag"))
                    writeContinuation?.resume(throwing: NFCError.writingFailed("Incompatible tag"))
                    return
                }

                if let readContinuation = readContinuation {
                    let (status, _) = try await miFareTag.queryNDEFStatus()
                    guard status != .notSupported else {
                        throw NFCError.readingFailed("Tag doesn't support NDEF")
                    }

                    let message = try await miFareTag.readNDEF()
                    guard let record = message.records.first,
                          let uuid = parseUUIDFromTextPayload(record.payload) else {
                        throw NFCError.invalidData
                    }

                    self.readContinuation = nil
                    self.tagReadSession = nil

                    session.alertMessage = "Tag read successfully"
                    session.invalidate()
                    readContinuation.resume(returning: uuid)
                    return
                }

                if let writeContinuation = writeContinuation {
                    let (status, _) = try await miFareTag.queryNDEFStatus()
                    guard status != .notSupported else {
                        self.writeContinuation = nil
                        self.writeSession = nil
                        self.spoolIDToWrite = nil

                        session.alertMessage = "Tag doesn't support NDEF"
                        session.invalidate()
                        writeContinuation.resume(throwing: NFCError.writingFailed("Tag doesn't support NDEF"))
                        return
                    }

                    guard let spoolID = spoolIDToWrite else {
                        self.writeContinuation = nil
                        self.writeSession = nil

                        session.alertMessage = "No data to write"
                        session.invalidate()
                        writeContinuation.resume(throwing: NFCError.writingFailed("No data to write"))
                        return
                    }

                    let uuidString = spoolID.uuidString
                    let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
                        string: uuidString,
                        locale: Locale(identifier: "en")
                    )

                    guard let payload else {
                        self.writeContinuation = nil
                        self.writeSession = nil
                        self.spoolIDToWrite = nil

                        session.alertMessage = "Failed to create payload"
                        session.invalidate()
                        writeContinuation.resume(throwing: NFCError.writingFailed("Failed to create payload"))
                        return
                    }

                    let message = NFCNDEFMessage(records: [payload])
                    try await miFareTag.writeNDEF(message)

                    self.writeContinuation = nil
                    self.writeSession = nil
                    self.spoolIDToWrite = nil

                    session.alertMessage = "Tag written successfully"
                    session.invalidate()
                    writeContinuation.resume()
                }
            } catch {
                let readContinuation = readContinuation
                let writeContinuation = writeContinuation

                self.readContinuation = nil
                self.writeContinuation = nil
                self.tagReadSession = nil
                self.writeSession = nil
                self.spoolIDToWrite = nil

                session.alertMessage = "Failed: \(error.localizedDescription)"
                session.invalidate()

                if let readContinuation {
                    readContinuation.resume(throwing: NFCError.readingFailed(error.localizedDescription))
                }

                if let writeContinuation {
                    writeContinuation.resume(throwing: NFCError.writingFailed(error.localizedDescription))
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
                tagReadSession = nil
            }

            if let continuation = writeContinuation {
                if userCancelled {
                    continuation.resume(throwing: NFCError.userCancelled)
                } else {
                    continuation.resume(throwing: NFCError.writingFailed(error.localizedDescription))
                }
                writeContinuation = nil
                writeSession = nil
                spoolIDToWrite = nil
            }
        }
    }
}
