import SwiftUI
import SwiftData

struct SpoolDetailView: View {
    @Bindable var spool: Spool

    var body: some View {
        Form {
            Section("Information") {
                LabeledContent("Manufacturer", value: spool.manufacturer)
                LabeledContent("Type", value: spool.type.displayName)
            }

            Section("Weight") {
                LabeledContent("Original", value: "\(Int(spool.originalWeight))g")

                HStack {
                    Text("Current")
                    Spacer()
                    TextField("Current", value: $spool.currentWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                }

                LabeledContent("Remaining") {
                    HStack {
                        Text(String(format: "%.1f%%", spool.remainingPercentage))
                        ProgressView(value: spool.remainingPercentage, total: 100)
                            .frame(width: 100)
                    }
                }
            }
        }
        .navigationTitle(spool.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }
}
