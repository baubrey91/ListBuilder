import SwiftUI
import GoogleSignIn
import AuthenticationServices

final class HomeViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate  {
    
    @Published var isLoggedIn = false
    
    func googlePreviousSession() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                self.saveTokenData(user: user)
                self.isLoggedIn = true
            }
        }
    }
    
    private func saveTokenData(user: GIDGoogleUser) {
        if let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg"),
        let expirationDate = user.accessToken.expirationDate {
            userDefaults.set(user.accessToken.tokenString, forKey: "accessToken")
            userDefaults.set(expirationDate, forKey: "expirationDate")
            userDefaults.synchronize()
        }
    }

    func googleSignIn() {
        
        // TODO: - put this in plist
        /*
         guard let clientID = GIDSignIn.sharedInstance.clientID else { return }

         let config = GIDConfiguration(clientID: clientID)

         */
        
        
        let clientID = "342648598752-nf6j0cmo2sc4omk4g5blod9q7mgjarf6.apps.googleusercontent.com"
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // As you’re not using view controllers to retrieve the presentingViewController, access it through
        // the shared instance of the UIApplication
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.configuration = config
        
  
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/drive"]) { result, error in

//        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/documents"]) { result, error in
            
            //        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] user, error in
            
            //      GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { [unowned self] user, error in
            
            if let error = error {
                print("Error doing Google Sign-In, \(error)")
                return
            }
            if let user = result?.user {
                self.saveTokenData(user: user)
                self.isLoggedIn = true
            }
//            doCall(user: user!.user)
            
        }
        

        
        func doCall(user: GIDGoogleUser) {
            
            // Define the URL of the API endpoint
            let urlString = "https://docs.googleapis.com/v1/documents/1ByPzag3JZUHSHJVaHZt7udDpG1iFKO0qV-c95G0ltQU"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }
            
            // Create a URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = "GET" // or "POST" if you need to send data
            
            // Set the Authorization header with the Bearer token
            let authToken = user.accessToken.tokenString // Replace with your actual token
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            // You can add additional headers if necessary
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Perform the network request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making request: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    // Check for success status code
                    if httpResponse.statusCode == 200 {
                        print("Request succeeded")
                        
                        // Process the response data
                        if let data = data {
                            do {
                                // For example, let's parse the response as JSON
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                    print("Response JSON: \(json)")
                                }
                            } catch {
                                print("Error parsing JSON: \(error)")
                            }
                        }
                    } else {
                        print("Request failed with status code: \(httpResponse.statusCode)")
                    }
                }
            }
            
            // Start the network request
            task.resume()
            
        }
    }
        
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        self.isLoggedIn = false
    }
}
