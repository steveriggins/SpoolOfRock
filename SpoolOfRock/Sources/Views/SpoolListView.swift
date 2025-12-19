import SwiftUI

struct SpoolListView: View {
    @Environment(\.spoolRepository) private var repository
    @State private var showingAddSpool = false

    private var spools: [Spool] {
        repository?.spools ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(spools) { spool in
                    NavigationLink(destination: SpoolDetailView(spool: spool)) {
                        SpoolRowView(spool: spool)
                    }
                }
                .onDelete(perform: deleteSpools)
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
        }
    }

    private func deleteSpools(offsets: IndexSet) {
        repository?.delete(at: offsets)
    }
}
