import SwiftUI
import OptiNoteShared

enum ImportImageViewState {
    case loading
    case loaded
    case error(message: String)
}

final class GoogleDriveListViewModel: ObservableObject {
    
    @Injected(\.networkProvider) var networkManager: NetworkManagerType
    
    @Published private var files: [DriveFile] = []
    @Published var searchText = ""
    @Published var isPresented = false
    @Published var state: ImportImageViewState = .loading
    
    var filteredFiles: [DriveFile] {
        guard !searchText.isEmpty else { return files }
        return files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var selectedFileText: String {
        if let fileName = PersistenceManager.shared.getPreviousFiles()?.first?.name {
            return Styler.fileSelectedText(with: fileName)
        } else {
            return Styler.fileSelectedError
        }
    }
    
    func setSelectedFile(file: DriveFile) {
        self.isPresented = true
        PersistenceManager.shared.setPreviousFiles(file: file)
    }
    
    func fetchFiles(for folderId: String?) {
        guard let accessToken = PersistenceManager.shared.getAccessToken() else {
            self.state = .error(message: Styler.invalidAccessToken)
            return
        }
        Task {
            do {
                let fetchedFiles: DriveFileList = try await networkManager.getData(
                    endpoint: .fetchFiles(folderId: folderId),
                    accessToken: accessToken
                )
                await MainActor.run {
                    self.files = fetchedFiles.files.sorted { $0.isFolder && $1.isGoogleDoc }
                }
            } catch let error {
                self.state = .error(message: error.localizedDescription)
            }
        }
    }
}

private enum Styler {
    static func fileSelectedText(with fileName: String) -> String {
        "All notes will be sent to the \(fileName) file."
    }
    static let fileSelectedError = "Error selecting file"
    static let invalidAccessToken = "Google session is invalid"
}
