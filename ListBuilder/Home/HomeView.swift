import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        if viewModel.isLoggedIn {
            NavigationStack {
                TabView {
                    ImportImageView()
                        .tabItem {
                            Label(
                                Styler.importText,
                                systemImage: Styler.importImage
                            )
                        }
                    GoogleDriveListView()
                        .tabItem {
                            Label(Styler.fileText, systemImage: Styler.fileImage)
                        }
                    // Placeholder
                    Text("Previous notes view")
                        .tabItem {
                            Label(Styler.previousNotesText, systemImage: Styler.previousNotesImage)
                        }
                }
                .navigationTitle("Home")
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
        } else {
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
            }.onAppear {
                self.viewModel.googlePreviousSession()
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
    static let previousNotesText = "Previous Notes"
    static let previousNotesImage = "clock.fill"
    
    //Previous Notes
    static let signInText = "Sign in with Google"
    static let signInImage = "globe"
}

