import SwiftUI
import OptiNoteShared

struct ShareView: View {
    
    @StateObject var viewModel: ShareViewModel
    
    var body: some View {
        switch self.viewModel.state {
        case .error(let error):
            Text("\(error.localizedDescription)")
            Button(action: {
                self.viewModel.closeShareView()
            }, label: {
                Text(Styler.dismissText)
            })
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        guard let image = await self.viewModel.getImage() else { return }
                        await MainActor.run {
                            self.viewModel.verifySessionAndFile(image: image)
                        }
                        //                //Should this be on background thread?
                        await self.viewModel.extractTextFromImage(from: image)
                    }
                }
        case .loadedWithNoResult:
            Text(Styler.noResults)
        default:
//            ScrollView {
                VStack {
                    Text(Styler.sendingToText(fileName: self.viewModel.currentFile?.name))
                    Text(Styler.textFound)
                    Text(viewModel.text)
                    TextField(
                        Styler.noTextFound,
                        text: $viewModel.text,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    HStack {
                        Button(action: {
                            self.viewModel.closeShareView()
                        }, label: {
                            Text(Styler.dismissText)
                        })
                        Button(action: {
                            Task {
                                await self.viewModel.sendUp(text: viewModel.text)
                            }
                        }, label: {
                            Text(Styler.sendToGoogleText)
                        })
                    }
                    HStack {
                        Text(Styler.previousFiles)
                        Picker(
                            "Previous Files",
                            selection: $viewModel.currentFile
                        ) {
                            ForEach(viewModel.previousFiles, id: \.self) { file in
                                Text(file.name)
                            }
                        }
                    }
                    if self.viewModel.isSendingData {
                        CustomSpinner()
                    }
                }

                .padding()
                .alert(isPresented: $viewModel.showingAlert) {
                    guard let alertType = self.viewModel.alertType else {
                        return Alert(title: Text(Styler.unknownErrorText))
                    }
                   return Alert(
                        title: Text(alertType.alertText),
                        dismissButton: .default(Text(Styler.goToAppText)) {
                            self.viewModel.openParentApp(with: alertType.deepLinkUrl)
                        }
                    )
                }
        }
    }
}

private enum Styler {
    static let dismissText = "Dismiss"
    
    static let noResults = "No results"
    
    static let textFound = "This is the text we found"
    static let noTextFound = "No text found"
    static let sendToGoogleText = "Send to Google"
    
    static let unknownErrorText = "Unknown Error"
    static let goToAppText = "Go to App"
    
    static let previousFiles = "Previous Files:"
    
    static func sendingToText(fileName: String?) -> String {
        return "Sending to: \(fileName ?? "Unknown File Name")"
    }
}
