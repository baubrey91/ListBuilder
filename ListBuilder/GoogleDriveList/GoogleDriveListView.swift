import SwiftUI


struct GoogleDriveListView: View {
    
    @StateObject private var viewModel = GoogleDriveListViewModel()
    
    let folderId: String

    // TODO: Remove hardcoded default folder
    
    init(folderId: String = "1rhTXfZREl_wCwhjcZ0zAcvaNY8CDYNkl") {
        self.folderId = folderId
    }
    
    var body: some View {
        List(self.viewModel.files) { file in
            if file.isFolder {
                NavigationLink(file.name) {
                    GoogleDriveListView(folderId: file.id)
                }
            } else {
                Button(file.name) {
                    self.viewModel.setSelectedFile(file: file)
//                    if let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg") {
//                        let encoded = Document(id: file.id, name: file.name).encoded
//                        userDefaults.set(encoded, forKey: "fileId")
//                        userDefaults.synchronize()
//                    }
                }
            }
        }
        .onAppear {
            self.viewModel.fetchFiles(folderId: self.folderId)
        }
    }
}
