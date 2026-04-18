import SwiftUI

enum ScanResultState: Hashable {
    case unknownTag
    case nfcError(String)
}

struct ScanResultView: View {
    @Environment(\.dismiss) private var dismiss

    let state: ScanResultState
    let onCreateSpool: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if case .unknownTag = state {
                    Button("Create Spool") {
                        dismiss()
                        onCreateSpool()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if case .nfcError = state {
                    Button(primaryButtonTitle) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(primaryButtonTitle) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconName: String {
        switch state {
        case .unknownTag:
            return "questionmark.circle"
        case .nfcError:
            return "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch state {
        case .unknownTag:
            return .orange
        case .nfcError:
            return .red
        }
    }

    private var title: String {
        switch state {
        case .unknownTag:
            return "Unknown NFC Tag"
        case .nfcError:
            return "Scan Failed"
        }
    }

    private var message: String {
        switch state {
        case .unknownTag:
            return "No spool in your library matches this tag yet."
        case .nfcError(let errorMessage):
            return errorMessage
        }
    }

    private var primaryButtonTitle: String {
        switch state {
        case .unknownTag:
            return "Back"
        case .nfcError:
            return "Try Again"
        }
    }
}
