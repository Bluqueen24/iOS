import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

struct GetAlbumsLinksViewWrapper: UIViewControllerRepresentable {
    private let albums: [AlbumEntity]
    
    init(albums: [AlbumEntity]) {
        self.albums = albums
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = makeViewModel(forAlbums: albums)
        return GetLinkViewController.instantiate(viewModel: viewModel)
    }
    
    private func makeViewModel(forAlbums albums: [AlbumEntity]) -> any GetLinkViewModelType {
        let shareAlbumUseCase = ShareAlbumUseCase(shareAlbumRepository: ShareAlbumRepository.newRepo)
        if albums.count == 1,
           let album = albums.first {
            let initialSections = ShareAlbumLinkInitialSections(album: album)
            return GetAlbumLinkViewModel(album: album,
                                         shareAlbumUseCase: shareAlbumUseCase,
                                         sectionViewModels: initialSections.initialLinkSectionViewModels,
                                         tracker: DIContainer.tracker)
        }
        let initialSections = ShareAlbumsLinkInitialSections(albums: albums,
                                                             thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
        return GetAlbumsLinkViewModel(albums: albums,
                                      shareAlbumUseCase: shareAlbumUseCase,
                                      sectionViewModels: initialSections.initialLinkSectionViewModels,
                                      tracker: DIContainer.tracker)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
