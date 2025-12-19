import SwiftUI

struct ContentView: View {
    var body: some View {
        SpoolListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Spool.self, inMemory: true)
}
