import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

protocol AlbumContentRouting: Routing {
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void)
    func showAlbumCoverPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void)
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell
    func showShareLink(album: AlbumEntity)
}

struct AlbumContentRouter: AlbumContentRouting {
    private weak var navigationController: UINavigationController?
    private let album: AlbumEntity
    private let newAlbumPhotos: [NodeEntity]?
    private let existingAlbumNames: () -> [String]
        
    init(navigationController: UINavigationController?, album: AlbumEntity, newAlbumPhotos: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) {
        self.navigationController = navigationController
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
        self.existingAlbumNames = existingAlbumNames
    }
    
    func build() -> UIViewController {
        let albumContentsUpdateRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let filesSearchRepo = FilesSearchRepository.newRepo
        let userAlbumRepo = UserAlbumRepository.newRepo
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsUpdateRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: filesSearchRepo),
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: userAlbumRepo
        )
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: PhotoLibraryRepository.newRepo,
                                                      searchRepository: FilesSearchRepository.newRepo)
        
        let alertViewModel = TextFieldAlertViewModel(textString: album.name,
                                                     title: Strings.Localizable.rename,
                                                     placeholderText: "",
                                                     affirmativeButtonTitle: Strings.Localizable.rename,
                                                     affirmativeButtonInitiallyEnabled: false,
                                                     highlightInitialText: true,
                                                     message: Strings.Localizable.renameNodeMessage,
                                                     validator: AlbumNameValidator(existingAlbumNames: existingAlbumNames).rename)
        
        let viewModel = AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
            photoLibraryUseCase: photoLibraryUseCase,
            shareAlbumUseCase: ShareAlbumUseCase(shareAlbumRepository: ShareAlbumRepository.newRepo),
            router: self,
            newAlbumPhotosToAdd: newAlbumPhotos,
            alertViewModel: alertViewModel)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    @MainActor
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        let photoLibraryRepository = PhotoLibraryRepository.newRepo
        let fileSearchRepository = FilesSearchRepository.newRepo
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                                      searchRepository: fileSearchRepository)
        
        let viewModel = AlbumContentPickerViewModel(album: album,
                                                    photoLibraryUseCase: photoLibraryUseCase,
                                                    completion: completion,
                                                    configuration: PhotoLibraryContentConfiguration(
                                                        selectLimit: 150,
                                                        scaleFactor: UIDevice().iPadDevice ? .five : .three)
                                                    )
        let content = AlbumContentPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(dismissibleView: content),
                                      animated: true)
    }
    
    @MainActor
    func showAlbumCoverPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void) {
        let filesSearchRepo = FilesSearchRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: AlbumContentsUpdateNotifierRepository.newRepo,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: UserAlbumRepository.newRepo
        )
        
        let viewModel = AlbumCoverPickerViewModel(album: album,
                                                  albumContentsUseCase: albumContentsUseCase, router: self,
                                                    completion: completion)
        let content = AlbumCoverPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(dismissibleView: content),
                                      animated: true)
    }
    
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell {
        
        let vm = AlbumCoverPickerPhotoCellViewModel(
            albumPhoto: albumPhoto,
            photoSelection: photoSelection,
            viewModel: PhotoLibraryModeAllViewModel(libraryViewModel: PhotoLibraryContentViewModel(library: PhotoLibrary())),
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
        
        return AlbumCoverPickerPhotoCell(viewModel: vm)
    }
    
    @MainActor
    func showShareLink(album: AlbumEntity) {
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         copyrightUseCase: CopyrightUseCase(
                                                            shareUseCase: ShareUseCase(
                                                                repo: ShareRepository.newRepo),
                                                            userAlbumRepository: UserAlbumRepository.newRepo))
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetAlbumsLinksViewWrapper(albums: [album])
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
        navigationController?.present(UIHostingController(dismissibleView: view),
                                      animated: true)
    }
    
    func start() {}
}
