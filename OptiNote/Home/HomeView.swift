import SwiftUI

enum Tab: Hashable {
    case importImageView
    case googleDriveListView
}

struct HomeView: View {
    
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        switch self.viewModel.state {
        case .loading:
            ProgressView()
                .onAppear {
                    self.viewModel.validateUser()
                }
        case .loggedIn:
            NavigationStack {
                TabView(selection: $viewModel.selectedTab) {
                    ImportImageView(deepLinkedImage: self.$viewModel.deepLinkedImage)
                        .tabItem {
                            Label(
                                Styler.importText,
                                systemImage: Styler.importImage
                            )
                        }
                        .tag(Tab.importImageView)
                    GoogleDriveListView()
                        .tabItem {
                            Label(Styler.fileText, systemImage: Styler.fileImage)
                        }
                        .tag(Tab.googleDriveListView)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            self.viewModel.googleSignOut()
                        }) {
                            Image(systemName: Styler.signOutImage)
                        }
                    }
                }
            }
            .onOpenURL { url in
                self.viewModel.fetchDeepLinkedImage()
                if url.absoluteString.contains("googleDrive") {
                    self.viewModel.selectedTab = .googleDriveListView
                }
            }
            
        case .loggedOut:
            Button(action: self.viewModel.googleSignIn) {
                HStack {
                    Image(systemName: Styler.signInImage)
                    Text(Styler.signInText)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color(red: 66/255, green: 133/255, blue: 244/255))
                .cornerRadius(8)
            }
        }
    }
}

private enum Styler {
    static let signOutImage = "door.right.hand.open"
    
    // Import Image
    static let importText = "Import Image"
    static let importImage = "document.viewfinder.fill"
    
    //Files Drive
    static let fileText = "Files View"
    static let fileImage = "folder.fill"
    
    //Previous Notes
    static let signInText = "Sign in with Google"
    static let signInImage = "globe"
}

