import Foundation


// MARK: - Protocol for dependency injection

protocol NetworkService {
    func sendData(endpoint: Endpoint, text: String) async throws
//    func sendData<T: Decodable>(endpoint: Endpoint) async throws -> T {
}

// MARK: Enums

// Errors
enum NetworkError: Error, LocalizedError {
    case badURL
    case requestFailed
    case invalidResponse
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "The URL is invalid."
        case .requestFailed: return "The network request failed."
        case .invalidResponse: return "The server returned an invalid response."
        case .decodingError: return "Failed to decode the response."
        case .unknown: return "An unknown error occurred."
        }
    }
}

final class NetworkManager: NetworkService {

    private let session: URLSession
    private let accessToken: String
    
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(session: URLSession = .shared, accessToken: String) {
        self.session = session
        self.accessToken = accessToken

//        self.accessToken = "ya29.a0AeXRPp4UqoXMpvbYk5uZZXadJFZGGdqf8sDYJadbTkPa94FAPvGB0KN5zmqbkdoloSukANKAJNDnsOFuS3T1kUJTDK6p4Aow9ZhbNqi4VIrf2FkXawWsdYOrhsWOGVoIqcyQMIiYuNPS2VqHCetvahSDUJNj6U1C8BJQ8oPNaCgYKARESARASFQHGX2Mi-M4qoKi5qZ2av3O9OGApNw0175"
        
    }
    
    // Function to fetch data using async/await
    func sendData(endpoint: Endpoint, text: String) async throws {
        guard let url = endpoint.url() else {
            throw NetworkError.badURL
        }
        
        print(url.absoluteString)
        // Make Network request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let location = InsertLocation(index: 1)
        let insertText = InsertText(location: location, text: text)
        let updateRequest = Update(requests: [Request(insertText: insertText)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode(updateRequest)
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let (data, response) = try await session.data(for: request)
        
        // Check for 200
        print(data)
        print(response)
        guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // Decode
//        do {
////            let decodedData = try decoder.decode(T.self, from: data)
//            return decodedData
//        } catch let error {
//            // TODO: Log Error
//            throw NetworkError.decodingError
//        }
    }
}


// Endpoints
enum Endpoint {
    case sendToDocs(docId: String)
    // https://covers.openlibrary.org/b/ID/\(coverId)-M.jpg
    
    var path: String {
        switch self {
        case .sendToDocs(let docId):
            "/v1/documents/\(docId):batchUpdate"
        }
    }
    
//    var queryParameters: [URLQueryItem]? {
//        switch self {
//        case .search(_, let limit):
//            return [URLQueryItem(name: "limit", value: "20"),
//                    URLQueryItem(name: "offset", value: "\(limit)")]
//        default:
//            return nil
//        }
//    }
    

    func url() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "docs.googleapis.com"
        components.path = path
        
//        if let queryParameters {
//            components.queryItems = queryParameters
//        }
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
