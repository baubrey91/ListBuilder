import UIKit

private enum UserDefaultsKeys {
    static let suiteName = "group.com.brandonaubrey.OptiNote.sg"
    static let accessTokenKey = "accessToken"
    static let expirationKey = "expirationDate"
//    static let fileKey = "fileId"
    static let previousFilesKey = "previousFiles"
    static let imageUrl = "imageUrl"
    static let imagePath = "sharedImage.png"
}

public struct PersistenceManager {
    
    public static let shared = PersistenceManager()
    private let userDefaults = UserDefaults(suiteName: UserDefaultsKeys.suiteName)
    private let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.brandonaubrey.OptiNote.sg")
    private init() {}
    
    public func setAccessToken(accessToken: String, expirationDate: Date?) {
        guard let userDefaults else { return }
        userDefaults.set(accessToken, forKey: UserDefaultsKeys.accessTokenKey)
        userDefaults.set(expirationDate, forKey: UserDefaultsKeys.expirationKey)
        userDefaults.synchronize()
    }
    
    public func getAccessToken() -> String? {
        userDefaults?.string(forKey: UserDefaultsKeys.accessTokenKey)
    }
    
    public func getTokenExpirationDate() -> Date? {
        userDefaults?.object(forKey: UserDefaultsKeys.expirationKey) as? Date
    }
    
//    public func setFile(file: DriveFile) {
//        guard let userDefaults,
//              let encoded = Document(id: file.id, name: file.name).encoded else { return }
//        userDefaults.set(encoded, forKey: UserDefaultsKeys.fileKey)
//        userDefaults.synchronize()
//    }
    
//    public func getFile() -> Document? {
//        guard let userDefaults,
//              let fileData = userDefaults.data(forKey: UserDefaultsKeys.fileKey) else { return nil }
//        return try? JSONDecoder().decode(Document.self, from: fileData)
//    }
    
    // TODO: Fix logic to cache files
    public func setPreviousFiles(file: DriveFile) {
        guard let userDefaults else { return }
        var filesArray = self.getPreviousFiles() ?? []
        filesArray.append(Document(id: file.id, name: file.name))
        let encoded = filesArray.encoded
        userDefaults.set(encoded, forKey: UserDefaultsKeys.previousFilesKey)
        userDefaults.synchronize()
    }
    
    public func getPreviousFiles() -> [Document]? {
        guard let userDefaults,
              let fileData = userDefaults.data(forKey: UserDefaultsKeys.previousFilesKey) else { return nil }
        return try? JSONDecoder().decode([Document].self, from: fileData)
    }
    
    public func setExtensionImage(imageUrl: String) {
        guard let userDefaults else { return }
        userDefaults.set(imageUrl, forKey: UserDefaultsKeys.imageUrl)
        userDefaults.synchronize()
    }
    
    public func getExtensionImage() -> String? {
        userDefaults?.string(forKey: UserDefaultsKeys.imageUrl)
    }
    
    // MARK: - File Manager
    
    public func saveImage(data: Data) {
        guard let containerURL = self.fileURL else { return }
        let fileURL = containerURL.appendingPathComponent(UserDefaultsKeys.imagePath)
        try? data.write(to: fileURL)
    }
    
    public func getImage() -> UIImage? {
        guard let fileURL = self.fileURL?.appendingPathComponent(UserDefaultsKeys.imagePath),
                let data = try? Data(contentsOf: fileURL),
                let uiImage = UIImage(data: data) else { return nil }
        try? FileManager.default.removeItem(at: fileURL)
        return uiImage
    }
}

extension Array where Element == Document {
    var encoded: Data? {
        try? JSONEncoder().encode(self)
    }
}
