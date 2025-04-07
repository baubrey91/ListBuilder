import SwiftUI

@main
struct ListBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print(url)
                }
        }
    }
}
