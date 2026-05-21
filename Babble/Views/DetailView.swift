import SwiftUI

struct DetailView: View {
    var viewModel: BabbleViewModel

    var body: some View {
        Group {
            if viewModel.isGenerating {
                progressContent
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Generation Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let metadata = viewModel.generationMetadata {
                textContent(metadata: metadata)
            } else {
                ContentUnavailableView(
                    "No Text Generated",
                    systemImage: "text.bubble",
                    description: Text("Select books and tap Generate.")
                )
            }
        }
        .navigationTitle("Generated Text")
    }

    private var progressContent: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.progress) {
                Text(progressLabel)
                    .font(.subheadline)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func textContent(metadata: BabbleViewModel.GenerationMetadata) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(metadata.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.horizontal)
                .padding(.vertical, 8)
            Divider()
            ScrollView {
                Text(viewModel.generatedText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private var progressLabel: String {
        switch viewModel.progress {
        case ..<0.1: return "Loading texts\u{2026}"
        case ..<0.3: return "Normalizing\u{2026}"
        case ..<0.9: return "Building model\u{2026}"
        default:     return "Generating\u{2026}"
        }
    }
}
