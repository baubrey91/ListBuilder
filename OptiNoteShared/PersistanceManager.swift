private enum UserDefaultsKeys {
    static let suiteName = "group.com.brandonaubrey.OptiNote.sg"
    static let accessTokenKey = "accessToken"
    static let expirationKey = "expirationDate"
    static let fileKey = "fileId"
    static let imageUrl = "imageUrl"
}

public struct PersistenceManager {
    
    public static let shared = PersistenceManager()
    private let userDefaults = UserDefaults(suiteName: UserDefaultsKeys.suiteName)
    
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
    
    public func setFile(file: DriveFile) {
        guard let userDefaults,
              let encoded = Document(id: file.id, name: file.name).encoded else { return }
        userDefaults.set(encoded, forKey: UserDefaultsKeys.fileKey)
        userDefaults.synchronize()
    }
    
    public func getFile() -> Document? {
        guard let userDefaults,
              let fileData = userDefaults.data(forKey: UserDefaultsKeys.fileKey) else { return nil }
        return try? JSONDecoder().decode(Document.self, from: fileData)
    }
    
    public func setExtensionImage(imageUrl: String) {
        guard let userDefaults else { return }
        userDefaults.set(imageUrl, forKey: UserDefaultsKeys.imageUrl)
        userDefaults.synchronize()
    }
    
    public func getExtensionImage() -> String? {
        userDefaults?.string(forKey: UserDefaultsKeys.imageUrl)
    }
}
