import SwiftUI
import NetworkingLB

final class GoogleDriveListViewModel: ObservableObject {
    
    @Published var files: [DriveFile] = []

    
//    init() {
//        Task {
//            await fetchFiles()
//        }
//    }
    
    func setSelectedFile(file: DriveFile) {
        // Persist in UserDefaults
        PersistenceManager.shared.setFile(file: file)
        
        // Set insert line
        self.setInsertLine(fileId: file.id)
    }
    
    private func setInsertLine(fileId: String) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
              let accessToken = userDefaults.string(forKey: "accessToken") else { return }
       
        let nm = NetworkManager(accessToken: accessToken)
        
        Task {
            do {
                let fileInfo: String = try await nm.getData(endpoint: .fetchFileInfo(fileId: fileId))
                let insertLine = fileInfo.components(separatedBy: .newlines).count
                print(insertLine)
                PersistenceManager.shared.setInsertLine(line: insertLine)
            } catch let error {
                print(error)
            }
        }
    }
    
    func fetchFiles(folderId: String) {
        
//        https://www.googleapis.com/drive/v3/files?q='1rhTXfZREl_wCwhjcZ0zAcvaNY8CDYNkl'%20in%20parents%20and%20(mimeType='application/vnd.google-apps.folder'%20or%20mimeType='application/vnd.google-apps.document')&fields=files(id,name,mimeType)
// https://www.googleapis.com/drive/v3/files?q='1rhTXfZREl_wCwhjcZ0zAcvaNY8CDYNkl'%2520in%2520parents%2520and%2520(mimeType%3D'application/vnd.google-apps.folder'%2520or%2520mimeType%3D'application/vnd.google-apps.document')&fields=files(id,name,mimeType))
//                let query = "'\(folderId)' in parents and (mimeType='application/vnd.google-apps.folder' or mimeType='application/vnd.google-apps.document')"
//                let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//                let urlStr = "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)&fields=files(id,name,mimeType)"
//        
//                guard let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
//                      let accessToken = userDefaults.object(forKey: "accessToken") else {
//                    fatalError()
//                }
//        
//                let url = URL(string: urlStr)!
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                request.setValue(
//                    "Bearer \(accessToken)",
//                    forHTTPHeaderField: "Authorization"
//                )

        
        
        guard let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
              let accessToken = userDefaults.string(forKey: "accessToken") else { return }
       
        let nm = NetworkManager(accessToken: accessToken)
        Task {
            do {
                let fetchedFiles: DriveFileList = try await nm.getData(endpoint: .fetchFiles(folderId: folderId))
                let docId = fetchedFiles.files.first { $0.isGoogleDoc }!
                let string: String = try await nm.getData(endpoint: .fetchFileInfo(fileId: docId.id))
                print(string.components(separatedBy: .newlines).count)
                await MainActor.run { self.files = fetchedFiles.files.sorted { $0.isFolder && $1.isGoogleDoc } }
            } catch let error {
                print(error)
            }
        }
        
//        let query = "'\(folderId)' in parents and (mimeType='application/vnd.google-apps.folder' or mimeType='application/vnd.google-apps.document')"
//        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//        let urlStr = "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)&fields=files(id,name,mimeType)"
//        
//        guard let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
//              let accessToken = userDefaults.object(forKey: "accessToken") else {
//            fatalError()
//        }
//        
//        let url = URL(string: urlStr)!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(
//            "Bearer \(accessToken)",
//            forHTTPHeaderField: "Authorization"
//        )
//        //        URLSession.shared.data(for: <#T##URLRequest#>)
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else { return }
//            
//            do {
//                let decoder = JSONDecoder()
//                let foo = try decoder.decode(DriveFileList.self, from: data)
//                Task { @MainActor in
//                    self.files = foo.files.sorted { $0.isFolder && !$1.isFolder }
//                }
//            } catch {
//                print("JSON error: \(error)")
//            }
//        }
//        task.resume()
    }
}
