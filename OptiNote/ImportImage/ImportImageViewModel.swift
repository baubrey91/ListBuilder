import SwiftUI
import Vision
import PhotosUI
import OptiNoteShared

final class ImportImageViewModel: ObservableObject {
    
    @Injected(\.networkProvider) var networkManager: NetworkManagerType

    @Published var path: Path?
    @Published var text: String = ""
    @Published var images: [UIImage] = [UIImage(named: "TestImage")!]
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
                let start = value.startLocation
                let end = value.location
                let rectangle = CGRect(
                    origin: CGPoint(x: min(start.x, end.x), y: min(start.y, end.y)),
                    size: CGSize(width: abs(end.x - start.x), height: abs(end.y - start.y))
                )

                self.path = Path { path in
                    path.addRect(rectangle)
                }
            }
            .onEnded { value in
                self.showingPopover = true
                let uiImage = self.images.first!
//                let displaySize = geo.size
                let originalSize = uiImage.size
                let scaleX = originalSize.width / self.screenWidth
                let scaleY = originalSize.height / (self.screenWidth * 1.5)
                
                
                let start = value.startLocation
                let end = value.location
       
                let rectangle = CGRect(x: value.startLocation.x * scaleX,
                                       y: value.startLocation.y * scaleY,
                                       width: (end.x - start.x) * scaleX,
                                       height: (end.y - start.y) * scaleY
                                       )
                let cropped = self.cropImage(image: uiImage, toRect: rectangle)!
                Task {
                    await self.extractTextFromImage(from: cropped.cgImage!)
                }
            }
    }
    
    func cropImage(image: UIImage, toRect cropRect: CGRect, imageSizeInView: CGSize, viewSize: CGSize) -> UIImage? {
         let scaleX = image.size.width / imageSizeInView.width
         let scaleY = image.size.height / imageSizeInView.height

         let scaledRect = CGRect(
             x: cropRect.origin.x * scaleX,
             y: cropRect.origin.y * scaleY,
             width: cropRect.width * scaleX,
             height: cropRect.height * scaleY
         )

         guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
         return UIImage(cgImage: cgImage)
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
            //TODO fix crash when tapping
            guard let res = request.results as? [VNRecognizedTextObservation] else { return }
//            for observation in requestResults.compactMap { $0 } {
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
    
    private func displayImages(selectedItems: [PhotosPickerItem]) {
        images = []
        Task {
            for item in selectedItems {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let imageData = UIImage(data: data) else {
                    print("Error")
                    return
                }
                await MainActor.run {
                    self.images.append(imageData)
                }
            }
        }
    }
    
    func sendToGoogle(text: String) {
        self.images.removeFirst()
        self.path = nil
        guard let accessToken = PersistenceManager.shared.getAccessToken(),
              let file = PersistenceManager.shared.getFile() else { return }
        Task {
            do {
                // Add Time stamp whens ending up
                let string: String = try await networkManager.getData(endpoint: .fetchFileInfo(fileId: file.id), accessToken: accessToken)
                let insertIndex = string.count
                let endpoint: Endpoint = .sendToDocs(docId: file.id, insertIndex: insertIndex, text: "\n" + text)
                try await networkManager.sendData(endpoint: endpoint, accessToken: accessToken)
            } catch let error {
                print(error)
            }
        }
    }
    
    func getCurrentFile() -> String {
        PersistenceManager.shared.getFile()?.name ?? "No File Selected"
    }
}
