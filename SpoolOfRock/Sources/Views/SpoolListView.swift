import SwiftUI

struct SpoolListView: View {
    @Environment(\.spoolRepository) private var repository
    @Environment(\.nfcManager) private var nfcManager

    @State private var showingAddSpool = false
    @State private var navigationPath = NavigationPath()

    private var spools: [Spool] {
        repository?.spools ?? []
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    VStack(spacing: 12) {
                        ActionCardButton(
                            title: "Scan Spool",
                            subtitle: "Scan an NFC tag to open its spool",
                            systemImage: "wave.3.right.circle.fill",
                            tint: .blue,
                            isLoading: nfcManager?.isReading ?? false,
                            action: startScan
                        )

                        ActionCardButton(
                            title: "Add Spool",
                            subtitle: "Create a new spool entry",
                            systemImage: "plus.circle.fill",
                            tint: .green,
                            isLoading: false,
                            action: { showingAddSpool = true }
                        )
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                if spools.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Spools",
                            systemImage: "cylinder.fill",
                            description: Text("Use Add Spool to create your first entry")
                        )
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Section("My Spools") {
                        ForEach(spools) { spool in
                            NavigationLink(value: spool) {
                                SpoolRowView(spool: spool)
                            }
                        }
                        .onDelete(perform: deleteSpools)
                    }
                }
            }
            .navigationDestination(for: Spool.self) { spool in
                SpoolDetailView(spool: spool)
            }
            .navigationDestination(for: ScanResultState.self) { state in
                ScanResultView(state: state) {
                    showingAddSpool = true
                }
            }
            .navigationTitle("Spool of Rock")
            .sheet(isPresented: $showingAddSpool) {
                AddSpoolView()
            }
        }
    }

    private func deleteSpools(offsets: IndexSet) {
        repository?.delete(at: offsets)
    }

    private func startScan() {
        guard let nfcManager else { return }

        Task {
            guard let tagID = await nfcManager.readTag() else {
                if let error = nfcManager.error {
                    navigationPath.append(ScanResultState.nfcError(error.localizedDescription))
                }
                return
            }

            if let spool = nfcManager.findSpool(for: tagID) {
                navigationPath.append(spool)
            } else {
                navigationPath.append(ScanResultState.unknownTag)
            }
        }
    }
}

private struct ActionCardButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
