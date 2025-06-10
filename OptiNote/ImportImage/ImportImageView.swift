import SwiftUI
import PhotosUI
import OptiNoteShared

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
                            height: viewModel.screenWidth * 1.5
                        )
                        .onAppear {
                            Task {
                                await viewModel.extractTextFromImage(from: uiImage.cgImage!)
                            }
                        }
                }
                if let path = viewModel.path {
                    path.stroke(style: StrokeStyle(lineWidth: 4, dash: [5]))
                }
            }
            .popover(isPresented: $viewModel.showingPopover) {
                processedTextPopover
            }
        }
        .gesture(viewModel.drawGesture())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                PhotosPicker(
                    selection: $viewModel.selectedItems,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Image(systemName: "photo")
                            .imageScale(.large)
                    }
            }
        }
        .onChange(of: deepLinkedImage) { newImage in
            if let newImage = newImage {
                viewModel.images = [newImage]
                Task {
                    await viewModel.extractTextFromImage(from: newImage.cgImage!)
                }
            }
        }
    }
    
    var processedTextPopover: some View {
        VStack {
            Text(self.viewModel.getCurrentFile())
            TextField(
                "No text found",
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
                    Text("Back")
                }
                Spacer()
                Button {
                    self.viewModel.sendToGoogle(text: viewModel.text)
                } label: {
                    Text("Send To Google")
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ImportImageView(deepLinkedImage: .constant(nil))
}


