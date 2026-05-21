import SwiftUI

struct ContentView: View {
    @State private var viewModel = BabbleViewModel()
    @State private var preferredColumn = NavigationSplitViewColumn.sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            SidebarView(viewModel: viewModel)
        } detail: {
            DetailView(viewModel: viewModel)
        }
        .onChange(of: viewModel.isGenerating) { _, isNowGenerating in
            // On iPhone (compact), auto-navigate to the detail pane when generation completes
            if !isNowGenerating, !viewModel.generatedText.isEmpty {
                preferredColumn = .detail
            }
        }
    }
}

#Preview {
    ContentView()
}
