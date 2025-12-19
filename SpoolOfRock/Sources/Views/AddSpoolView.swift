import SwiftUI
import SwiftData

struct AddSpoolView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var manufacturer = ""
    @State private var selectedType: FilamentType = .pla
    @State private var originalWeight = ""
    @State private var currentWeight = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Spool Information") {
                    TextField("Manufacturer", text: $manufacturer)

                    Picker("Filament Type", selection: $selectedType) {
                        ForEach(FilamentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Weight (grams)") {
                    TextField("Original Weight", text: $originalWeight)
                        .keyboardType(.decimalPad)

                    TextField("Current Weight", text: $currentWeight)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Spool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSpool()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }

    private var isValidInput: Bool {
        !manufacturer.isEmpty &&
        Double(originalWeight) != nil &&
        Double(currentWeight) != nil
    }

    private func saveSpool() {
        guard let original = Double(originalWeight),
              let current = Double(currentWeight) else {
            return
        }

        let newSpool = Spool(
            manufacturer: manufacturer,
            type: selectedType,
            originalWeight: original,
            currentWeight: current
        )

        modelContext.insert(newSpool)
        dismiss()
    }
}
