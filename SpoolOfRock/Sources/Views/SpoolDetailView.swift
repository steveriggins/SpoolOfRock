import SwiftUI

struct SpoolDetailView: View {
    @Environment(\.spoolRepository) private var repository

    let spool: Spool

    var body: some View {
        if let repository = repository {
            DetailContentContainer(spool: spool, repository: repository)
        } else {
            Text("Repository not available")
        }
    }
}

private struct DetailContentContainer: View {
    @State private var viewModel: SpoolDetailViewModel

    init(spool: Spool, repository: SpoolRepository) {
        _viewModel = State(initialValue: SpoolDetailViewModel(spool: spool, repository: repository))
    }

    var body: some View {
        DetailContent(viewModel: viewModel)
            .onDisappear {
                viewModel.save()
            }
    }
}

private struct DetailContent: View {
    @Bindable var viewModel: SpoolDetailViewModel

    var body: some View {
        Form {
            Section("Information") {
                LabeledContent("Manufacturer", value: viewModel.manufacturer)
                LabeledContent("Type", value: viewModel.type.displayName)
                LabeledContent("Color", value: viewModel.color)
            }

            Section("Weight") {
                LabeledContent("Original", value: "\(Int(viewModel.originalWeight))g")

                HStack {
                    Text("Current")
                    Spacer()
                    TextField("Current", value: $viewModel.currentWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                }

                LabeledContent("Remaining") {
                    HStack {
                        Text(String(format: "%.1f%%", viewModel.remainingPercentage))
                        ProgressView(value: viewModel.remainingPercentage, total: 100)
                            .frame(width: 100)
                    }
                }
            }
        }
        .navigationTitle(viewModel.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }
}
