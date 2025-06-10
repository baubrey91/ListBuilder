import SwiftUI
import GoogleSignIn
import AuthenticationServices
import OptiNoteShared

enum HomeState {
    case loading
    case loggedIn
    case loggedOut
}

final class HomeViewModel: NSObject, ObservableObject {
    
    @Published var state: HomeState = .loading
    @Published var selectedTab: Tab
    @Published var deepLinkedImage: UIImage? = nil
    
    init(selectedTab: Tab = .importImageView) {
        _selectedTab = Published(initialValue: selectedTab)
    }
    
    private var isLoggedIn: Bool {
        GIDSignIn.sharedInstance.currentUser != nil
    }
    
    func validateUser() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                self.state = .loggedIn
                self.saveTokenData(user: user)
            } else {
                self.state = .loggedOut
            }
        }
    }

    func googleSignIn() {
        let clientID = "342648598752-nf6j0cmo2sc4omk4g5blod9q7mgjarf6.apps.googleusercontent.com"
        let config = GIDConfiguration(clientID: clientID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive"]
        ) { result, error in
            if let error = error {
                print("Error doing Google Sign-In, \(error)")
                return
            }
            if let user = result?.user {
                self.saveTokenData(user: user)
                self.state = .loggedIn
            }
        }
    }
        
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        self.state = .loggedOut
    }
    
    func fetchDeepLinkedImage() {
        let fileManager = FileManager.default
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.brandonaubrey.OptiNote.sg") {
            let fileURL = containerURL.appendingPathComponent("sharedImage.png")
            if let data = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: data) {
                self.deepLinkedImage = uiImage
                try! fileManager.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - Private
private extension HomeViewModel {
    func saveTokenData(user: GIDGoogleUser) {
        PersistenceManager.shared.setAccessToken(
            accessToken: user.accessToken.tokenString,
            expirationDate: user.accessToken.expirationDate
        )
    }
}
