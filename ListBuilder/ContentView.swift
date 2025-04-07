import SwiftUI

struct ContentView: View {
    @StateObject var authService = AuthService()

    var body: some View {
        
        VStack {
            if authService.isLoggedIn() {
                VStack {
                    Text("You are Logged in")
                    Button {
                        authService.googleSignOut()
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            Button {
//                authService.googleSignIn()
                authService.googlePreviousSession()
            } label: {
                Text("Login")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

