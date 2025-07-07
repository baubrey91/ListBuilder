public struct Document: Codable, Hashable {
    public let id: String
    public let name: String
    
    var encoded: Data? {
        try? JSONEncoder().encode(self)
    }
}

public struct DriveFileList: Codable {
    public let files: [DriveFile]
}

public struct DriveFile: Codable, Identifiable {
    public let id: String
    public let name: String
    public let mimeType: String

    public var isFolder: Bool {
        return mimeType == "application/vnd.google-apps.folder"
    }

    public var isGoogleDoc: Bool {
        return mimeType == "application/vnd.google-apps.document"
    }
}
