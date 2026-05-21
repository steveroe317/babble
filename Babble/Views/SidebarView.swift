import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: BabbleViewModel

    var body: some View {
        VStack(spacing: 0) {
            generateButtonArea
            Divider()
            List {
                ParametersView(viewModel: viewModel)
                BookSelectionView(viewModel: viewModel)
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Babble")
    }

    private var generateButtonArea: some View {
        Group {
            if viewModel.isGenerating {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Generating\u{2026}")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Button("Generate", systemImage: "wand.and.stars") {
                    Task { await viewModel.generate() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding()
                .disabled(!viewModel.canGenerate)
            }
        }
    }
}
