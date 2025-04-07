import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        isModalInPresentation = true
        
        if let itemProviders = (extensionContext?.inputItems as? [NSExtensionItem])?.first?.attachments {
            let viewModel = ShareViewModel(itemProviders: itemProviders, extensionContext: extensionContext)
            let rootView = ShareView(viewModel: viewModel)
            
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.view.frame = view.frame
            view.addSubview(hostingController.view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TODO: Refactor
        super.viewWillAppear(animated)
        self.checkAccessToken()
    }
    
    private func checkAccessToken() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
           let experationDate = userDefaults.object(forKey: "expirationDate") as? Date else {
            // Access Token/ Expiration date is not set
            self.openParentApp()
            return
        }
        // Token has expired
        if experationDate < Date() {
            self.openParentApp()
        }
    }
    
    private func openParentApp() {
        if let url = URL(string: "mainApp://") {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
        }
    }
    
//    func openParentAppOne() {
//        if let url = URL(string: "mainApp://refresh") {
//            let appExtensionContext = self.extensionContext
//            appExtensionContext?.open(url, completionHandler: { (success) in
//                print(url)
//                if success {
//                    print("Main app opened successfully!")
//                } else {
//                    print("Failed to open the main app.")
//                }
//            })
//
////            var responder: UIResponder? = self
////            while responder != nil {
////                if let application = responder as? UIApplication {
////                    application.open(url)
////                    break
////                }
////                responder = responder?.next
////            }
//        }
//    }

}
