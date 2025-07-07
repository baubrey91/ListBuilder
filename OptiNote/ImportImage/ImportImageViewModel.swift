import SwiftUI
import Vision
import PhotosUI
import OptiNoteShared

enum AlertType {
    case noImage
    case errorCropping
    
    var alertText: String {
        switch self {
        case .noImage: "Import an image first"
        case .errorCropping: "Error processing image"
        }
    }
}

final class ImportImageViewModel: ObservableObject {
    
    @Injected(\.networkProvider) var networkManager: NetworkManagerType

    @Published var path: Path?
    @Published var text: String = ""
    // TODO: Remove before finalizing
    @Published var images: [UIImage] = [UIImage(named: "TestImage")!]
    @Published var alertType: AlertType?
    @Published var errorText: String?
    @Published var isSendingData: Bool = false
    @Published var showingAlert = false
    @Published var showingPopover = false
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            self.displayImages(selectedItems: selectedItems)
        }
    }

    let screenWidth = UIScreen.main.bounds.size.width
    
    func drawGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let rectangle = self.createOnChangedRect(value: value)
                self.path = Path { path in
                    path.addRect(rectangle)
                }
            }
            .onEnded { value in
                self.showingPopover = true
                guard let uiImage = self.images.first else {
                    self.showingAlert = true
                    self.alertType = .noImage
                    return
                }
                
                guard let croppedImage = self.cropImage(
                    image: uiImage,
                    toRect: uiImage.getRect(value: value, screenWidth: self.screenWidth)
                )?.cgImage else {
                    self.showingAlert = true
                    self.alertType = .errorCropping
                    return
                }
                Task {
                    await self.extractTextFromImage(from: croppedImage)
                }
            }
    }
    
    func cropImage(image: UIImage, toRect cropRect: CGRect) -> UIImage? {
        let scaledRect = CGRect(
            x: cropRect.origin.x * image.scale,
            y: cropRect.origin.y * image.scale,
            width: cropRect.size.width * image.scale,
            height: cropRect.size.height * image.scale
        )

        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            self.text = scaledRect.debugDescription
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func extractTextFromImage(from image: CGImage) async {
        let request = VNRecognizeTextRequest { request, error in
            var recognizedText = ""
            guard let res = request.results as? [VNRecognizedTextObservation] else { return }
            for observation in res {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += topCandidate.string + "\n"
            }
            Task { @MainActor in
                self.text = recognizedText.replacingOccurrences(of: "\n", with: " ").lowercased()
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
    }
    
    func sendToGoogle(text: String) {
        Task { @MainActor in
            self.isSendingData = true
        }
        self.path = nil
        guard let accessToken = PersistenceManager.shared.getAccessToken(),
              let file = PersistenceManager.shared.getPreviousFiles()?.first else { return }
        Task {
            do {
                let string: String = try await networkManager.getData(endpoint: .fetchFileInfo(fileId: file.id), accessToken: accessToken)
                let insertIndex = string.count
                let endpoint: Endpoint = .sendToDocs(docId: file.id, insertIndex: insertIndex, text: "\n" + text)
                try await networkManager.sendData(endpoint: endpoint, accessToken: accessToken)
                Task { @MainActor in
                    self.images.removeFirst()
                    self.showingPopover = false
                    self.isSendingData = false
                }
            } catch let error {
                Task { @MainActor in
                    self.errorText = error.localizedDescription
                    self.isSendingData = false
                }
            }
        }
    }
    
    func getCurrentFile() -> String {
        PersistenceManager.shared.getPreviousFiles()?.first?.name ?? "No File Selected"
    }
}

private extension ImportImageViewModel {
    
    func displayImages(selectedItems: [PhotosPickerItem]) {
        images = []
        Task {
            for item in selectedItems {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let imageData = UIImage(data: data) else {
                    return
                }
                await MainActor.run {
                    self.images.append(imageData)
                }
            }
        }
    }
    
    func createOnChangedRect(value: DragGesture.Value) -> CGRect {
        let start = value.startLocation
        let end = value.location
        return CGRect(
            origin: CGPoint(
                x: min(start.x, end.x),
                y: min(start.y, end.y)
            ),
            size: CGSize(
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
        )
    }
}

