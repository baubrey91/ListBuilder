import UniformTypeIdentifiers
import Vision
import SwiftUI
import OptiNoteShared

enum ViewModelState {
    case loading
    case loadedWithResult
    case loadedWithNoResult
    case error(Error)
}

enum ShareViewError: Error {
    case loadingImageFailed
    case convertingImageFailed
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
            return "optinote://googledrive"
        }
    }
}

final class ShareViewModel: ObservableObject {
    
    @Injected(\.networkProvider) var networkManager: NetworkManagerType
    
    @Published var text = ""
    @Published var state: ViewModelState = .loading
    @Published var showingAlert = false
    @Published var alertType: AlertType?
    @Published var isSendingData: Bool = false

    let previousFiles: [Document] = PersistenceManager.shared.getPreviousFiles() ?? []

    private var openParentAppClosure: (String) -> Void
    
    var currentFile: Document? = PersistenceManager.shared.getPreviousFiles()?.first
    
    private var extensionContext: NSExtensionContext?
    private var photoItem: NSItemProvider?

    
    init(extensionContext: NSExtensionContext?, openParentAppClosure: @escaping (String) -> Void) {
        self.openParentAppClosure = openParentAppClosure
        self.extensionContext = extensionContext
        let itemProviders = (extensionContext?.inputItems as? [NSExtensionItem])?.first?.attachments
        self.photoItem = itemProviders?.first
    }
    
    func getImage() async -> CGImage? {
        do {
            let imageUrl = try await photoItem?.loadItem(forTypeIdentifier: UTType.image.identifier) as? URL
            guard let cgImage = imageUrl?.toCGImage() else {
                self.state = .error(ShareViewError.loadingImageFailed)
                return nil
            }
            return cgImage
        } catch let error {
            self.state = .error(error)
            return nil
        }
    }
    
    func verifySessionAndFile(image: CGImage) {
        guard self.accessTokenValid(),
              self.fileExist(),
              let data = UIImage(cgImage: image).pngData() else { return }
        PersistenceManager.shared.saveImage(data: data)
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
                self.text = "\n" + recognizedText.replacingOccurrences(of: "\n", with: " ").lowercased()
                self.state = recognizedText.isEmpty ? .loadedWithNoResult : .loadedWithResult
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
    }
    
    func sendUp(text: String) async {
        await MainActor.run {
            self.isSendingData = true
        }
        guard let accessToken = PersistenceManager.shared.getAccessToken() else {
            return
        }
        
        guard let fileId = currentFile?.id else {
            //TODO: file error
            return
        }
            Task {
                do {
                    let string: String = try await networkManager.getData(
                        endpoint: .fetchFileInfo(fileId: fileId),
                        accessToken: accessToken
                    )
                    let insertIndex = string.count

                    try await networkManager.sendData(
                        endpoint: .sendToDocs(
                            docId: fileId,
                            insertIndex: insertIndex,
                            text: text
                        ),
                        accessToken: accessToken
                    )
                    await MainActor.run {
                        self.isSendingData = false
                        self.closeShareView()
                    }
                } catch {
                    await MainActor.run {
                        self.isSendingData = false
                    }
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
        guard PersistenceManager.shared.getPreviousFiles() == nil else { return true }
        DispatchQueue.main.async {
            self.showingAlert = true
            self.alertType = .noFileSelected
        }
        return false
    }
    
    func openParentApp(with urlString: String) {
        self.openParentAppClosure(urlString)
        self.closeShareView()
    }
    
    func closeShareView() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
