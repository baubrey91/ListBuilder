import UIKit
import SwiftUI
import OptiNoteShared

final class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        let viewModel = ShareViewModel(extensionContext: extensionContext, openParentAppClosure: openParentApp)
        let rootView = ShareView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.frame = view.frame
        view.addSubview(hostingController.view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.checkAccessToken()
//        self.checkFile()
    }
}

private extension ShareViewController {
    
    func foo(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier("public.image") {
            provider.loadItem(forTypeIdentifier: "public.image", options: nil) { (item, error) in
                if let url = item as? URL {
                    // Copy the file to the shared container
                    let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.yourapp")!
                    let destURL = sharedURL.appendingPathComponent("shared_image.jpg")
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: destURL)
                    } catch {
                        print("Error copying: \(error)")
                    }
                }
            }
        }
    }
    
//    func checkAccessToken() {
//        guard PersistenceManager.shared.getAccessToken() != nil else {
//            self.makeAlert(alertType: .noToken)
//            return
//        }
//        guard let expirationDate = PersistenceManager.shared.getTokenExpirationDate(),
//              expirationDate > Date() else {
//            self.makeAlert(alertType: .expiredToken)
//            return
//        }
//    }
//    
//    func checkFile() {
//        guard PersistenceManager.shared.getFile() == nil else { return }
//        // TODO: Deeplink to file selection
//        self.makeAlert(alertType: .noFileSelected)
//    }
    
    func openParentApp(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }
    }
    
    func makeAlert(alertType: AlertType) {
        let popup = UIAlertController(
            title: alertType.alertText,
            message: "Continue in App",
            preferredStyle: .alert
        )

        let ok = UIAlertAction(
            title: "OK",
            style: .default
        ) { _ in
            self.openParentApp(with: alertType.deepLinkUrl)
        }

        popup.addAction(ok)
        present(popup, animated: true, completion: nil)
    }
}
