import SwiftUI
import SwiftData

struct SpoolRowView: View {
    let spool: Spool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(spool.manufacturer)
                    .font(.headline)
                Spacer()
                Text(spool.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                ProgressView(value: spool.remainingPercentage, total: 100)
                Text("\(Int(spool.currentWeight))g / \(Int(spool.originalWeight))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
