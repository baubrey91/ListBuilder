import UniformTypeIdentifiers
import Vision
import SwiftUI

final class ShareViewModel: ObservableObject {
    var itemProviders: [NSItemProvider]
    var extensionContext: NSExtensionContext?
    @Published var text: String?
    
    init(itemProviders: [NSItemProvider], extensionContext: NSExtensionContext?) {
        self.itemProviders = itemProviders
        self.extensionContext = extensionContext
    }
    
    func getImage() async -> UIImage? {
        do {
            let item = self.itemProviders.first!
            let data = try! await item.loadDataRepresentation(for: .image)
            return UIImage(data: data)
        } catch {
            print("Error")
        }
    }
    
    func extractTextFromImage(from image: UIImage) {
        guard let image = image.cgImage else {
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error during OCR: \(error.localizedDescription)")
                return
            }
            
            var recognizedText = ""
            for observation in request.results as! [VNRecognizedTextObservation] {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += topCandidate.string + "\n"
            }
            self.text = recognizedText.replacingOccurrences(of: "\n", with: " ")
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
    func loadDataRepresentation(for type: UTType) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadDataRepresentation(for: type) { data, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
