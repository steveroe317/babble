import SwiftUI

struct ParametersView: View {
    @Bindable var viewModel: BabbleViewModel

    var body: some View {
        Section("Parameters") {
            Stepper(
                "Max N-gram order: \(viewModel.maxNGramOrder)",
                value: $viewModel.maxNGramOrder,
                in: 1...5
            )
            .disabled(viewModel.isGenerating)

            LabeledContent("Output length") {
                Stepper(
                    "\(viewModel.outputLength)",
                    value: $viewModel.outputLength,
                    in: 100...2000,
                    step: 100
                )
            }
            .disabled(viewModel.isGenerating)
        }
    }
}
