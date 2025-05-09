import SwiftUI

struct ShareView: View {
    @StateObject var viewModel: ShareViewModel
    
    var body: some View {
        
        switch self.viewModel.state {
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        // TODO: Remove force unwrap
                        let image = try! await self.viewModel.getImage()
                        //                //Should this be on background thread?
                        await self.viewModel.extractTextFromImage(from: image)
                    }
                }
        case .loadedWithNoResult:
            Text("No Results")
        default:
//            ScrollView {
                VStack {
                    Text("This is the text we found")
                    Text(viewModel.text)
                    TextEditor(text: $viewModel.text)
                        .frame(minHeight: 40, maxHeight: 200, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Button(action: {
                        Task {
                            //TODO: Start spinner
                            // TODO: Fix
                            await self.viewModel.sendUp(text: viewModel.text, insertIndex: 1)
                        }
                    }, label: {
                        Text("Send to Google")
                    })
                }
                //            }
//            }
        }
    }
}



// Async function to recognize text from an image
//    func recognizeText(from image: UIImage) async -> String? {
//        // Convert UIImage to CIImage
//        guard let ciImage = CIImage(image: image) else {
//            print("Unable to create CIImage from UIImage.")
//            return nil
//        }
//
//        // Create a text recognition request
//        let textRequest = VNRecognizeTextRequest { request, error in
//            // Check for errors
//            if let error = error {
//                print("Text recognition failed: \(error.localizedDescription)")
//                return
//            }
//
//            // Process recognized text
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                print("No text found.")
//                return
//            }
//
//            // Concatenate recognized text from all observations
//            var text = ""
//            for observation in observations {
//                if let topCandidate = observation.topCandidates(1).first {
//                    text += topCandidate.string + "\n"
//                }
//            }
//
//            // Return the recognized text asynchronously
//            Task { @MainActor in
//                // Use the result (UI update on main thread)
//                if text.isEmpty {
//                    self.text = "No text was recognized."
//                } else {
//                    self.text = text
//                }
//            }
//        }
//
//        // Set the recognition level (optional)
//        textRequest.recognitionLevel = .accurate
//
//        // Create a request handler
//        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//
//        do {
//            // Perform the request asynchronously
//            try await requestHandler.perform([textRequest])
//            return nil
//        } catch {
//            print("Error performing text recognition: \(error.localizedDescription)")
//            return nil
//        }
//    }

//import AuthenticationServices
//import GoogleSignIn
//
//final class AuthService: NSObject, ObservableObject, ASAuthorizationControllerDelegate  {
//    
//    func isLoggedIn() -> Bool {
//        GIDSignIn.sharedInstance.currentUser != nil
//    }
//    
//    func googlePreviousSession() {
//        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//            if let userDefaults = UserDefaults(suiteName: "group.com.brandonaubrey.ListBuilder.sg") {
//                userDefaults.set(user?.accessToken.tokenString as AnyObject, forKey: "accessToken")
//                userDefaults.synchronize()
//            }
////            UserDefaults.standard.set(user!.accessToken, forKey: "Access Token")
////            self.updateDoc(accessToken: user!.accessToken.tokenString)
//        }
//    }
//    
//
//
//    func googleSignIn(view: UIViewController) {
//        
//        let clientID = "342648598752-nf6j0cmo2sc4omk4g5blod9q7mgjarf6.apps.googleusercontent.com"
////        // Create Google Sign In configuration object.
//        let config = GIDConfiguration(clientID: clientID)
////        
////        // As you’re not using view controllers to retrieve the presentingViewController, access it through
////        // the shared instance of the UIApplication
////        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
////        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
////        
////        // Start the sign in flow!
//        GIDSignIn.sharedInstance.configuration = config
//        
//        GIDSignIn.sharedInstance.signIn(withPresenting: view, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/documents"]) {
//            [unowned self] user, error in
//            }
//        }
//        
//        
//        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/documents"]) {
//            [unowned self] user, error in
//            
//            //        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] user, error in
//            
//            //      GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { [unowned self] user, error in
//            
//            if let error = error {
//                print("Error doing Google Sign-In, \(error)")
//                return
//            }
//            
//            
//            doCall(user: user!.user)
//            
//            GIDSignIn.sharedInstance.currentUser?.accessToken
//            print("-----")
//            print(user?.user.accessToken.tokenString)
//            print("-----")
//            //            guard let authentication = user?.authentication else { return }
//            //            let accessToken = authentication.accessToken
//            //            print(user?.user.profile)
//            //
//            //          guard
//            //            let authentication = user?.authentication,
//            //            let idToken = authentication.idToken
//            //          else {
//            //            print("Error during Google Sign-In authentication, \(error)")
//            //            return
//            //          }
//            //
//            //          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
//            //                                                         accessToken: authentication.accessToken)
//            //
//            //
//            //            // Authenticate with Firebase
//            //            Auth.auth().signIn(with: credential) { authResult, error in
//            //                if let e = error {
//            //                    print(e.localizedDescription)
//            //                }
//            //
//            //                print("Signed in with Google")
//            //            }
//        }
//        
//        func doCall(user: GIDGoogleUser) {
//            
//            // Define the URL of the API endpoint
//            let urlString = "https://docs.googleapis.com/v1/documents/1ByPzag3JZUHSHJVaHZt7udDpG1iFKO0qV-c95G0ltQU"
//            guard let url = URL(string: urlString) else {
//                print("Invalid URL")
//                return
//            }
//            
//            // Create a URLRequest
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET" // or "POST" if you need to send data
//            
//            // Set the Authorization header with the Bearer token
//            let authToken = user.accessToken.tokenString // Replace with your actual token
//            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//            
//            // You can add additional headers if necessary
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            // Perform the network request
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("Error making request: \(error)")
//                    return
//                }
//                
//                if let httpResponse = response as? HTTPURLResponse {
//                    // Check for success status code
//                    if httpResponse.statusCode == 200 {
//                        print("Request succeeded")
//                        
//                        // Process the response data
//                        if let data = data {
//                            do {
//                                // For example, let's parse the response as JSON
//                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                                    print("Response JSON: \(json)")
//                                }
//                            } catch {
//                                print("Error parsing JSON: \(error)")
//                            }
//                        }
//                    } else {
//                        print("Request failed with status code: \(httpResponse.statusCode)")
//                    }
//                }
//            }
//            
//            // Start the network request
//            task.resume()
//            
//        }
//    }
//        
//    func googleSignOut() {
//        GIDSignIn.sharedInstance.signOut()
//    }
//}
//
