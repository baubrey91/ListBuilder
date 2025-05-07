import SwiftUI
import PhotosUI

struct ImportImageView: View {
    
    @StateObject var viewModel = ImportImageViewModel()

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.gray
                if let uiImage = viewModel.images.first {
//                    GeometryReader { geo in
                        Image(uiImage: uiImage)
                            .resizable()
//                            .scaledToFit()
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
//                }
                if let path = viewModel.path {
                    path.stroke(style: StrokeStyle(lineWidth: 4, dash: [5]))
                }
            }

            Spacer()
//            PhotosPicker(
//                selection: $viewModel.selectedItems,
//                matching: .images,
//                photoLibrary: .shared()) {
//                    Image(systemName: "photo")
//                        .imageScale(.large)
//                }
            if let text = viewModel.text {
                Text(text)
                Button {
                    //Put into helper function
                    self.viewModel.images.removeFirst()
                    self.viewModel.path = nil
                    self.viewModel.sendToGoogle(text: text)
                } label: {
                    Text("Send To Google")
                }
//                Spacer()
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
    }
}



#Preview {
    HomeView()
}


