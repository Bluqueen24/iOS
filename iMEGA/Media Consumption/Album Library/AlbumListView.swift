import SwiftUI

@available(iOS 14.0, *)
struct AlbumListView: View {
    @StateObject var viewModel: AlbumListViewModel
    var router: AlbumListViewRouting
    
    @State private var isPresenting = false
    
    var body: some View {
        ZStack(alignment: .topTrailing)  {
            GeometryReader { proxy in
                if viewModel.shouldLoad {
                    ProgressView()
                        .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        LazyVGrid(columns: viewModel.columns, spacing: 0) {
                            router.cell(withCameraUploadNode: viewModel.cameraUploadNode, album: nil)
                                .onTapGesture(count: 1)  {
                                    isPresenting.toggle()
                                }
                                .clipped()
                            
                            ForEach(viewModel.albums, id: \.self) { album in
                                router.cell(withCameraUploadNode: nil, album: album)
                                    .clipped()
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
        .fullScreenCover(isPresented: $isPresenting) {
            router.albumContent(for: viewModel.cameraUploadNode)
                .ignoresSafeArea()
        }
        .padding([.top, .bottom], 10)
        .onAppear {
            viewModel.loadAlbums()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}
