import SwiftUI

struct SpoolDetailView: View {
    @Environment(\.spoolRepository) private var repository
    @State private var viewModel: SpoolDetailViewModel?

    let spool: Spool

    var body: some View {
        Group {
            if let viewModel = viewModel {
                DetailContent(viewModel: viewModel)
            }
        }
        .onAppear {
            if let repository = repository, viewModel == nil {
                viewModel = SpoolDetailViewModel(spool: spool, repository: repository)
            }
        }
        .onDisappear {
            viewModel?.save()
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
