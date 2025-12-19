import SwiftUI

struct SpoolListView: View {
    @Environment(\.spoolRepository) private var repository
    @Environment(\.nfcManager) private var nfcManager
    @State private var showingAddSpool = false
    @State private var navigationPath = NavigationPath()
    @State private var showingUnknownTagAlert = false
    @State private var scannedUnknownTagID: UUID?

    private var spools: [Spool] {
        repository?.spools ?? []
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(spools) { spool in
                    NavigationLink(value: spool) {
                        SpoolRowView(spool: spool)
                    }
                }
                .onDelete(perform: deleteSpools)
            }
            .navigationDestination(for: Spool.self) { spool in
                SpoolDetailView(spool: spool)
            }
            .navigationTitle("My Spools")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSpool = true }) {
                        Label("Add Spool", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSpool) {
                AddSpoolView()
            }
            .overlay {
                if spools.isEmpty {
                    ContentUnavailableView(
                        "No Spools",
                        systemImage: "cylinder.fill",
                        description: Text("Tap + to add your first spool")
                    )
                }
            }
            .onAppear {
                startBackgroundNFCReading()
            }
            .onDisappear {
                nfcManager?.stopBackgroundReading()
            }
            .alert("Unknown NFC Tag", isPresented: $showingUnknownTagAlert) {
                Button("Create New Spool") {
                    showingAddSpool = true
                }
                Button("Cancel", role: .cancel) {
                    scannedUnknownTagID = nil
                }
            } message: {
                Text("This NFC tag is not associated with any spool. Would you like to create a new spool?")
            }
        }
    }

    private func deleteSpools(offsets: IndexSet) {
        repository?.delete(at: offsets)
    }

    private func startBackgroundNFCReading() {
        guard let nfcManager = nfcManager else { return }

        nfcManager.startBackgroundReading { tagID in
            // Find spool with this NFC tag ID
            if let spool = repository?.spools.first(where: { $0.nfcTagIdentifier == tagID.uuidString }) {
                // Navigate to the spool's detail view
                navigationPath.append(spool)
            } else {
                // Unknown tag - offer to create new spool
                scannedUnknownTagID = tagID
                showingUnknownTagAlert = true
            }
        }
    }
}
