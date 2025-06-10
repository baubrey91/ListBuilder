import SwiftUI


struct GoogleDriveListView: View {
    
    @StateObject private var viewModel = GoogleDriveListViewModel()

    let folderId: String?

    init(folderId: String? = nil) {
        self.folderId = folderId
    }
    
    var body: some View {
        NavigationStack {
            List(self.viewModel.filteredFiles) { file in
                if file.isFolder {
                    NavigationLink(file.name) {
                        GoogleDriveListView(folderId: file.id)
                    }
                } else {
                    Button(file.name) {
                        self.viewModel.setSelectedFile(file: file)
                    }
                    .alert(
                        Styler.fileChanged,
                        isPresented: $viewModel.isPresented,
                        actions: {},
                        message: {
                            Text(self.viewModel.selectedFileText)
                        }
                    )
                }
            }
            .searchable(
                text: $viewModel.searchText,
                prompt: Styler.search
            )
            .onAppear {
                self.viewModel.fetchFiles(for: self.folderId)
            }
        }
    }
}

private enum Styler {
    static let fileChanged = "Current File Changed"
    static let search = "Search Drive"
}
