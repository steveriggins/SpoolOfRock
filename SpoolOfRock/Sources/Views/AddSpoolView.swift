import SwiftUI

struct AddSpoolView: View {
    @Environment(\.spoolRepository) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.nfcManager) private var nfcManager

    @State private var manufacturer = ""
    @State private var selectedType: FilamentType = .pla
    @State private var color = ""
    @State private var originalWeight = ""
    @State private var currentWeight = ""
    @State private var scannedTagID: String?
    @State private var showingError = false

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

                if let nfcManager = nfcManager, nfcManager.isNFCAvailable {
                    Section("NFC Tag (Optional)") {
                        if scannedTagID != nil {
                            Label("Tag Ready to Assign", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }

                        Button {
                            Task {
                                if let tagID = await nfcManager.readTag() {
                                    scannedTagID = tagID.uuidString
                                } else if nfcManager.error != nil {
                                    showingError = true
                                }
                            }
                        } label: {
                            HStack {
                                Label("Scan NFC Tag", systemImage: "wave.3.right")
                                if nfcManager.isReading {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(nfcManager.isReading)
                    }
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
            .alert("NFC Error", isPresented: $showingError, presenting: nfcManager?.error) { _ in
                Button("OK") {
                    nfcManager?.clearError()
                }
            } message: { error in
                Text(error.localizedDescription)
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

        // Assign NFC tag if one was scanned
        newSpool.nfcTagIdentifier = scannedTagID

        repository?.add(newSpool)
        dismiss()
    }
}
