import SwiftUI

struct BookSelectionView: View {
    @Bindable var viewModel: BabbleViewModel

    var body: some View {
        Section("Books") {
            ForEach(BookSource.all) { book in
                Toggle(isOn: Binding(
                    get: { viewModel.selectedBooks.contains(book) },
                    set: { included in
                        if included {
                            viewModel.selectedBooks.insert(book)
                        } else {
                            viewModel.selectedBooks.remove(book)
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                        Text(book.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(viewModel.isGenerating)
            }
        }
    }
}
