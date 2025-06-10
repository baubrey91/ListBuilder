import UniformTypeIdentifiers
import Vision
import SwiftUI
import OptiNoteShared

enum ViewModelState {
    case loading
    case loadedWithResult
    case loadedWithNoResult
    case failed(Error)
}

enum AlertType {
    case noToken
    case expiredToken
    case noFileSelected
    
    var alertText: String {
        switch self {
        case .noToken:
            "You need to log into Google first"
        case .expiredToken:
            "Google session expired"
        case .noFileSelected:
            "No file selected"
        }
    }
    
    var deepLinkUrl: String {
        switch self {
        case .noToken, .expiredToken:
            return "optinote://signIn"
        case .noFileSelected:
            return "optinote://googleDrive"
        }
    }
}

final class ShareViewModel: ObservableObject {
    
    @Injected(\.networkProvider) var networkManager: NetworkManagerType
    
    @Published var text = ""
    @Published var state: ViewModelState = .loading
    @Published var showingAlert = false
    @Published var alertType: AlertType?
    
    private var openParentAppClosure: (String) -> Void
    
    var currentFile: String {
        PersistenceManager.shared.getFile()?.name ?? "No File Selected"
    }
    
//    var itemProviders: [NSItemProvider]
    var extensionContext: NSExtensionContext?
    private var photoItem: NSItemProvider?

    
    init(extensionContext: NSExtensionContext?, openParentAppClosure: @escaping (String) -> Void) {
        self.openParentAppClosure = openParentAppClosure
        self.extensionContext = extensionContext
        let itemProviders = (extensionContext?.inputItems as? [NSExtensionItem])?.first?.attachments
        self.photoItem = itemProviders?.first
    }
    
    enum tempError: Error {
        case foo
    }
    
    func getImage() async throws -> CGImage {
        do {
            //TODO: Remove force unwrap
            let imageUrl = try await photoItem?.loadItem(forTypeIdentifier: UTType.image.identifier) as? URL
            guard let cgImage = imageUrl?.toCGImage() else { throw tempError.foo }
            return cgImage
        } catch let error {
            throw error
        }
    }
    
    func verifySessionAndFile(image: CGImage) async {
        if !self.accessTokenValid() || !self.fileExist() {
            guard let data = UIImage(cgImage: image).pngData() else { return }
            let fileManager = FileManager.default
            if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.brandonaubrey.OptiNote.sg") {
                let fileURL = containerURL.appendingPathComponent("sharedImage.png")
                try? data.write(to: fileURL)
            }
        }
    }
    
    func extractTextFromImage(from image: CGImage) async {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                // TODO: throw error
                return
            }
            
            var recognizedText = ""
            for observation in request.results as! [VNRecognizedTextObservation] {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += topCandidate.string + "\n"
            }
            Task { @MainActor in
                self.text = recognizedText.replacingOccurrences(of: "\n", with: " ").lowercased()
                self.state = recognizedText.isEmpty ? .loadedWithNoResult : .loadedWithResult
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
    }
    
    func sendUp(text: String, insertIndex: Int) async {
        guard let accessToken = PersistenceManager.shared.getAccessToken() else {
            //TODO: access token error
            return
        }
        
        guard let document = PersistenceManager.shared.getFile() else {
            //TODO: file error
            return
        }
            Task {
                do {
                    try await networkManager.sendData(
                        endpoint: .sendToDocs(
                            docId: document.id,
                            insertIndex: insertIndex,
                            text: text
                        ),
                        accessToken: accessToken
                    )
                } catch let error {
                    print(error)
                }
            }
    }
    
    
    //TODO: Make all private
    func accessTokenValid() -> Bool {
        guard PersistenceManager.shared.getAccessToken() != nil else {
            self.showingAlert = true
            self.alertType = .noToken
            return false
        }
        guard let expirationDate = PersistenceManager.shared.getTokenExpirationDate(),
              expirationDate > Date() else {
            self.showingAlert = true
            self.alertType = .expiredToken
            return false
        }
        return true
    }
    
    func fileExist() -> Bool {
        guard PersistenceManager.shared.getFile() == nil else { return true }
        DispatchQueue.main.async {
            self.showingAlert = true
            self.alertType = .noFileSelected
        }
        return false
    }
    
    func openParentApp(with urlString: String) {
        self.openParentAppClosure(urlString)
    }
}
