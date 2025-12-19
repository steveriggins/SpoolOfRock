import SwiftUI

struct AddSpoolView: View {
    @Environment(\.spoolRepository) private var repository
    @Environment(\.dismiss) private var dismiss

    @State private var manufacturer = ""
    @State private var selectedType: FilamentType = .pla
    @State private var color = ""
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

                    TextField("Color", text: $color)
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
            color: color,
            originalWeight: original,
            currentWeight: current
        )

        repository?.add(newSpool)
        dismiss()
    }
}
