import UniformTypeIdentifiers
import Vision
import SwiftUI
import NetworkingLB

enum ViewModelState {
    case loading
    case loadedWithResult
    case loadedWithNoResult
    case failed(Error)
}

final class ShareViewModel: ObservableObject {
    @Published var text = "Hello"
    @Published var state: ViewModelState = .loading
    
    var itemProviders: [NSItemProvider]
    var extensionContext: NSExtensionContext?

    
    init(itemProviders: [NSItemProvider], extensionContext: NSExtensionContext?) {
        self.itemProviders = itemProviders
        self.extensionContext = extensionContext
    }
    
    enum tempError: Error {
        case foo
    }
    
//    func getImage() async throws -> UIImage {
//        let extensionAttachments = (self.extensionContext!.inputItems.first as! NSExtensionItem).attachments
//        for provider in extensionAttachments! {
//            // loadItem can be used to extract different types of data from NSProvider object in attachements
//            provider.loadItem(forTypeIdentifier: "public.image") { data, _ in
//                // Load Image data from image URL
//                guard let url = data as? URL,
//                      let imageData = try? Data(contentsOf: url) else { return nil }
//                // Load Image as UIImage from image data
//                let uiimg = UIImage(data: imageData)!
//                // Convert to SwiftUI Image
//                let image = Image(uiImage: uiimg)
//                // .. Do something with the Image
//            }
//        }
//    }
    
    func getImage() async throws -> CGImage {
        do {
            //TODO: Remove force unwrap
            let item = self.itemProviders.first!
            let imageUrl = try await item.loadItem(forTypeIdentifier: UTType.image.identifier) as? URL
            if let cgImage = imageUrl?.toCGImage() {
                return cgImage
            } else {
                throw tempError.foo
            }
        } catch let error {
            throw error
        }
    }
    
    func extractTextFromImage(from image: CGImage) async {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
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
    
    func sendUp(text: String) async {
        if let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
            let value1 = userDefaults.string(forKey: "accessToken") {
            let nm = NetworkManager(accessToken: value1)
            Task {
                do {
                    try await nm.sendData(endpoint: .sendToDocs(docId: "1ByPzag3JZUHSHJVaHZt7udDpG1iFKO0qV-c95G0ltQU"), text: text)
                } catch let error {
                    print(error)
                }
            }
        }
    }
}

extension NSItemProvider {
    func loadDataRepresentation(for type: UTType) async throws -> CGImage? {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadItem(forTypeIdentifier: "public.image") { data, error in
                continuation.resume(returning: nil)
                // Load Image data from image URL
//                let url = data as! URL
//                let imageData = try! Data(contentsOf: url)
//                //TODO: Throw errors
//                continuation.resume(returning: UIImage(data: imageData)!.cgImage!)
            }
        }
            
//        return try await withCheckedThrowingContinuation { continuation in
//            self.loadDataRepresentation(for: type) { data, error in
//                if let data = data {
//                    continuation.resume(returning: data)
//                } else if let error = error {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
    }
}

extension URL {
    func toCGImage() -> CGImage? {
        guard let imageData = try? Data(contentsOf: self),
              let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.cgImage
    }
}
