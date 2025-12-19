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
    @State private var showingError = false

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
                            Task {
                                let success = await nfcManager.writeTagForSpool(viewModel.spool)
                                if !success && nfcManager.error != nil {
                                    showingError = true
                                }
                            }
                        } label: {
                            HStack {
                                Label(
                                    viewModel.spool.nfcTagIdentifier == nil ? "Assign NFC Tag" : "Reassign NFC Tag",
                                    systemImage: "wave.3.right"
                                )
                                if nfcManager.isWriting {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(nfcManager.isWriting)
                    } else {
                        Text("NFC not available on this device")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(viewModel.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
        .alert("NFC Error", isPresented: $showingError, presenting: nfcManager?.error) { _ in
            Button("OK") {
                nfcManager?.clearError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
