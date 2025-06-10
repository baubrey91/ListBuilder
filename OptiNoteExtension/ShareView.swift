import SwiftUI
import OptiNoteShared

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
                        await self.viewModel.verifySessionAndFile(image: image)
                    }
                }
        case .loadedWithNoResult:
            Text("No Results")
        default:
//            ScrollView {
                VStack {
                    Text("Sending to: \(viewModel.currentFile)")
                    Text("This is the text we found")
                    Text(viewModel.text)
                    TextField(
                        "No text found",
                        text: $viewModel.text,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    HStack {
                        Button(action: {
                            self.viewModel.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                        }, label: {
                            Text("Dismiss")
                        })
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
                }
                .alert(isPresented: $viewModel.showingAlert) {
                    guard let alertType = self.viewModel.alertType else {
                        return Alert(title: Text("Unknown Error"))
                    }
                   return Alert(
                        title: Text(alertType.alertText),
                        dismissButton: .default(Text("Go to app")) {
                            self.viewModel.openParentApp(with: alertType.deepLinkUrl)
                        }
                    )
                }
        }
    }
}



