import UIKit
import SwiftUI

public extension URL {
    func toCGImage() -> CGImage? {
        guard let imageData = try? Data(contentsOf: self),
              let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.cgImage
    }
}

public extension UIImage {
    func getRect(value: DragGesture.Value, screenWidth: Double) -> CGRect {

        let originalSize = self.size
        let scaleX = originalSize.width / screenWidth
        let scaleY = originalSize.height / (screenWidth * 1.5)
        
        let start = value.startLocation
        let end = value.location

        return CGRect(
            x: value.startLocation.x * scaleX,
            y: value.startLocation.y * scaleY,
            width: (end.x - start.x) * scaleX,
            height: (end.y - start.y) * scaleY
        )
    }
    
    func cropImage(
        toRect cropRect: CGRect,
        imageSizeInView: CGSize,
        viewSize: CGSize
    ) -> UIImage? {
         let scaleX = self.size.width / imageSizeInView.width
         let scaleY = self.size.height / imageSizeInView.height

         let scaledRect = CGRect(
             x: cropRect.origin.x * scaleX,
             y: cropRect.origin.y * scaleY,
             width: cropRect.width * scaleX,
             height: cropRect.height * scaleY
         )

         guard let cgImage = self.cgImage?.cropping(to: scaledRect) else { return nil }
         return UIImage(cgImage: cgImage)
     }
}
