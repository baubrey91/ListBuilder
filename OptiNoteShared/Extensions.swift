import UIKit

public extension URL {
    func toCGImage() -> CGImage? {
        guard let imageData = try? Data(contentsOf: self),
              let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.cgImage
    }
}
