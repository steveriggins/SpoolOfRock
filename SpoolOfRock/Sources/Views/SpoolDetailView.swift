import SwiftUI

struct SpoolDetailView: View {
    @Environment(\.spoolRepository) private var repository

    let spool: Spool

    var body: some View {
        if let repository = repository {
            DetailContentContainer(spool: spool, repository: repository)
        } else {
            Text("Repository not available")
        }
    }
}

private struct DetailContentContainer: View {
    @State private var viewModel: SpoolDetailViewModel

    init(spool: Spool, repository: SpoolRepository) {
        _viewModel = State(initialValue: SpoolDetailViewModel(spool: spool, repository: repository))
    }

    var body: some View {
        DetailContent(viewModel: viewModel)
            .onDisappear {
                viewModel.save()
            }
    }
}

private struct DetailContent: View {
    @Bindable var viewModel: SpoolDetailViewModel
    @Environment(\.nfcManager) private var nfcManager
    @Environment(\.dismiss) private var dismiss
    @State private var activeAlert: DetailAlert?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Information") {
                LabeledContent("Manufacturer", value: viewModel.manufacturer)
                LabeledContent("Type", value: viewModel.type.displayName)
                LabeledContent("Color", value: viewModel.color)
            }

            Section("Weight") {
                LabeledContent("Original", value: "\(Int(viewModel.originalWeight))g")

                HStack {
                    Text("Current")
                    Spacer()
                    TextField("Current", value: $viewModel.currentWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                }

                LabeledContent("Remaining") {
                    HStack {
                        Text(String(format: "%.1f%%", viewModel.remainingPercentage))
                        ProgressView(value: viewModel.remainingPercentage, total: 100)
                            .frame(width: 100)
                    }
                }
            }

            if let nfcManager = nfcManager {
                Section("NFC Tag") {
                    if nfcManager.isNFCAvailable {
                        if viewModel.spool.nfcTagIdentifier != nil {
                            HStack {
                                Label("Tag Assigned", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    nfcManager.removeTagFromSpool(viewModel.spool)
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        Button {
                            beginTagAssignmentFlow()
                        } label: {
                            HStack {
                                Label(
                                    viewModel.spool.nfcTagIdentifier == nil ? "Assign NFC Tag" : "Reassign NFC Tag",
                                    systemImage: "wave.3.right"
                                )
                                if nfcManager.isWriting || nfcManager.isReading {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(nfcManager.isWriting || nfcManager.isReading)
                    } else {
                        Text("NFC not available on this device")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            Section {
                Button("Delete Spool", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(viewModel.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this spool?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Spool", role: .destructive) {
                viewModel.deleteSpool()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .nfcError(let message):
                return Alert(
                    title: Text("NFC Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        nfcManager?.clearError()
                    }
                )
            case .tagInUse(let spool):
                return Alert(
                    title: Text("Tag Already In Use"),
                    message: Text("This tag is currently assigned to \(spool.manufacturer). Reassign it to this spool?"),
                    primaryButton: .destructive(Text("Reassign")) {
                        Task {
                            guard let nfcManager else { return }
                            nfcManager.removeTagFromSpool(spool)
                            await writeTagToCurrentSpool(with: nfcManager)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func beginTagAssignmentFlow() {
        guard let nfcManager else { return }

        Task {
            guard let scannedTagID = await nfcManager.readTag() else {
                showNFCErrorIfAvailable()
                return
            }

            if let existingSpool = nfcManager.findSpool(for: scannedTagID), existingSpool.id != viewModel.spool.id {
                activeAlert = .tagInUse(existingSpool)
                return
            }

            await writeTagToCurrentSpool(with: nfcManager)
        }
    }

    private func writeTagToCurrentSpool(with nfcManager: NFCManager) async {
        let success = await nfcManager.writeTagForSpool(viewModel.spool)
        if !success {
            showNFCErrorIfAvailable()
        }
    }

    private func showNFCErrorIfAvailable() {
        if let error = nfcManager?.error {
            activeAlert = .nfcError(error.localizedDescription)
        }
    }
}

private enum DetailAlert: Identifiable {
    case nfcError(String)
    case tagInUse(Spool)

    var id: String {
        switch self {
        case .nfcError(let message):
            return "nfcError-\(message)"
        case .tagInUse(let spool):
            return "tagInUse-\(spool.id.uuidString)"
        }
    }
}
