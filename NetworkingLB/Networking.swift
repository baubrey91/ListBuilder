import Foundation

// MARK: - Protocol for dependency injection

protocol NetworkService {
    func sendData(endpoint: Endpoint, text: String) async throws
    func getData<T: Decodable>(endpoint: Endpoint) async throws -> T
}

// MARK: Enums

// Errors
enum NetworkError: Error, LocalizedError {
    case badURL
    case requestFailed
    case invalidResponse
    case decodingError
    case encodingFailure
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "The URL is invalid."
        case .requestFailed: return "The network request failed."
        case .invalidResponse: return "The server returned an invalid response."
        case .decodingError: return "Failed to decode the response."
        case .encodingFailure: return "Failed to encode the request."
        case .unknown: return "An unknown error occurred."
        }
    }
}

public final class NetworkManager: NetworkService {

    private let session: URLSession
    private let accessToken: String
    
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    public init(
        session: URLSession = .shared,
        accessToken: String
    ) {
        self.session = session
        self.accessToken = accessToken

//        self.accessToken = "ya29.a0AeXRPp4UqoXMpvbYk5uZZXadJFZGGdqf8sDYJadbTkPa94FAPvGB0KN5zmqbkdoloSukANKAJNDnsOFuS3T1kUJTDK6p4Aow9ZhbNqi4VIrf2FkXawWsdYOrhsWOGVoIqcyQMIiYuNPS2VqHCetvahSDUJNj6U1C8BJQ8oPNaCgYKARESARASFQHGX2Mi-M4qoKi5qZ2av3O9OGApNw0175"
        
    }
    
    public func getData<T: Decodable>(endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url() else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        
        let (data, response) = try await session.data(for: request)
        print(response)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        //TODO: Clean up
        if !endpoint.url()!.absoluteString.contains("text/plain") {
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return decodedData
            } catch {
                throw NetworkError.decodingError
            }
        } else {
            return try handleFileResponse(data: data)
        }
    }
    
    private func handleFileResponse<T>(data: Data) throws -> T {
        if let text = String(data: data, encoding: .utf8) {
            // Handle text data (plain text, HTML)
            if let result = text as? T {
                return result
            }
        }
        // If data is binary (like PDF), handle saving or returning raw data
        if let result = data as? T {
            return result
        }

        throw NetworkError.decodingError
    }
    
    // Function to fetch data using async/await
    public func sendData(
        endpoint: Endpoint,
        text: String
    ) async throws {
        guard let url = endpoint.url() else {
            throw NetworkError.badURL
        }
        
        // Make Network request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let location = InsertLocation(index: 1)
        let insertText = InsertText(location: location, text: text)
        let updateRequest = Update(requests: [Request(insertText: insertText)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(updateRequest)
            
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            let (_, response) = try await session.data(for: request)
            
            // Check for 200
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
        } catch {
            throw NetworkError.encodingFailure
        }
    }
}

// Endpoints
public enum Endpoint {
    case sendToDocs(docId: String)
    case fetchFiles(folderId: String)
    case fetchFileInfo(fileId: String)
    
    var host: String {
        switch self {
        case .sendToDocs:
            "docs.googleapis.com"
        case .fetchFiles, .fetchFileInfo:
            "www.googleapis.com"
        }
    }
    
    var path: String {
        switch self {
        case .sendToDocs(let docId):
            "/v1/documents/\(docId):batchUpdate"
        case .fetchFiles:
            "/drive/v3/files"
            
            //TODO: Move to queryParam
        case .fetchFileInfo(let fileId):
            "/drive/v3/files/\(fileId)/export"
        }
    }
    
    var queryParameters: [URLQueryItem]? {
        switch self {
        case .fetchFiles(let folderId):
            let query = "'\(folderId)' in parents and (mimeType='application/vnd.google-apps.folder' or mimeType='application/vnd.google-apps.document')"
            return [URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "fields", value: "files(id,name,mimeType)")]
        case .fetchFileInfo:
            return [URLQueryItem(name: "mimeType", value: "text/plain")]
        default:
            return nil
        }
    }

    func url() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        
        if let queryParameters {
            components.queryItems = queryParameters
        }
        
        guard let url = components.url else {
            //TODO: Log error or throw error if needed
            return nil
        }
        
        return url
    }
}

struct InsertLocation: Codable {
    let index: Int
}

struct InsertText: Codable {
    let location: InsertLocation
    let text: String
}

struct Request: Codable {
    let insertText: InsertText
}

struct Update: Codable {
    let requests: [Request]
}

enum UserDefaultsKeys {
    static let suiteName = "group.com.brandonaubrey.ListBuilder.sg"
    static let fileKey = "fileId"
    static let insertLineKey = "insertLine"
}

public struct PersistenceManager {
    
    public static let shared = PersistenceManager()
    private let userDefaults = UserDefaults(suiteName: UserDefaultsKeys.suiteName)
    
    private init() {}
    
    public func setFile(file: DriveFile) {
        guard let userDefaults,
              let encoded = Document(id: file.id, name: file.name).encoded else {
            return
        }
        userDefaults.set(encoded, forKey: UserDefaultsKeys.fileKey)
        userDefaults.synchronize()
    }
    
    public func setInsertLine(line: Int) {
        guard let userDefaults else { return }
        userDefaults.integer(forKey: UserDefaultsKeys.insertLineKey)
        userDefaults.synchronize()
    }
}

public struct Document: Codable {
    public let id: String
    let name: String
    
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
