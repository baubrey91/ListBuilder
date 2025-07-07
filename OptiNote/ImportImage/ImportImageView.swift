import SwiftUI
import PhotosUI
import OptiNoteShared

#Preview {
    ImportImageView(deepLinkedImage: .constant(nil))
}


struct ImportImageView: View {
    
    @StateObject var viewModel = ImportImageViewModel()
    @Binding var deepLinkedImage: UIImage?
    
    init(deepLinkedImage: Binding<UIImage?>) {
        self._deepLinkedImage = deepLinkedImage
    }

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.gray
                if let uiImage = viewModel.images.first {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(
                            width: viewModel.screenWidth,
                            height: viewModel.screenWidth * Styler.screenHeightMultiplier
                        )
                        .onAppear {
                            Task {
                                await viewModel.extractTextFromImage(from: uiImage.cgImage!)
                            }
                        }
                }
                if let path = viewModel.path {
                    path.stroke(style: Styler.strokeStyle)
                }
            }
            .popover(isPresented: $viewModel.showingPopover) {
                processedTextPopover
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            return .init(title: Text(viewModel.alertType?.alertText ?? Styler.unknownError))

        }
        .gesture(viewModel.drawGesture())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                PhotosPicker(
                    selection: $viewModel.selectedItems,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Image(systemName: Styler.photoImageName)
                            .imageScale(.large)
                    }
            }
        }
        .onChange(of: deepLinkedImage) { _, newImage in
            if let newImage = newImage,
            let cgImage = newImage.cgImage {
                viewModel.images = [newImage]
                Task {
                    await viewModel.extractTextFromImage(from: cgImage)
                }
            }
        }
    }
    
    var processedTextPopover: some View {
        VStack {
            Text(self.viewModel.getCurrentFile())
            TextField(
                Styler.noTextFound,
                text: $viewModel.text,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .padding()
            HStack {
                Spacer()
                Button {
                    self.viewModel.showingPopover = false
                } label: {
                    Text(Styler.backText)
                }
                Spacer()
                Button {
                    self.viewModel.sendToGoogle(text: viewModel.text)
                } label: {
                    Text(Styler.sendToGoogle)
                }
                Spacer()
            }
            if self.viewModel.isSendingData {
                CustomSpinner()
            }
            if let errorText = self.viewModel.errorText {
                Text(errorText)
            }
        }
    }
}

private enum Styler {
    static let screenHeightMultiplier: CGFloat = 1.5
    static let strokeStyle = StrokeStyle(lineWidth: 4, dash: [5])
    static let photoImageName = "photo"
    static let noTextFound = "No Text Found"
    static let backText = "Back"
    static let sendToGoogle = "Send To Google"
    static let unknownError = "Unknown Error"
}
