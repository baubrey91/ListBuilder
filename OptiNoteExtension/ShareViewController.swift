import UIKit
import SwiftUI
import OptiNoteShared

final class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        let viewModel = ShareViewModel(
            extensionContext: extensionContext,
            openParentAppClosure: openParentApp
        )
        let rootView = ShareView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.frame = view.frame
        view.addSubview(hostingController.view)
    }
}

private extension ShareViewController {
    
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
            message: Styler.continueString,
            preferredStyle: .alert
        )

        let ok = UIAlertAction(
            title: Styler.OkString,
            style: .default
        ) { _ in
            self.openParentApp(with: alertType.deepLinkUrl)
        }

        popup.addAction(ok)
        present(popup, animated: true, completion: nil)
    }
}

private enum Styler {
    static let continueString = "Continue In App"
    static let OkString = "OK"
}
