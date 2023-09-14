import Combine
import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

final class AlbumCellViewModel: ObservableObject {
    @Published var numberOfNodes: Int = 0
    @Published var thumbnailContainer: any ImageContaining
    @Published var isLoading: Bool = false
    @Published var title: String = ""
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue && selection.isAlbumSelected(album) != isSelected {
                selection.albums[album.id] = isSelected ? album : nil
            }
        }
    }

    @Published var editMode: EditMode = .inactive {
        willSet {
            opacity = newValue.isEditing && album.systemAlbum ? 0.5 : 1.0
            shouldShowEditStateOpacity = newValue.isEditing && !album.systemAlbum ? 1.0 : 0.0
        }
    }
    
    @Published var shouldShowEditStateOpacity: Double = 0.0
    @Published var opacity: Double = 1.0
    
    let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    let selection: AlbumSelection
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var isEditing: Bool {
        selection.editMode.isEditing
    }
    
    let isLinkShared: Bool
    
    init(
        thumbnailUseCase: any ThumbnailUseCaseProtocol,
        album: AlbumEntity,
        selection: AlbumSelection,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.album = album
        self.selection = selection
        self.tracker = tracker
        
        title = album.name
        numberOfNodes = album.count
        isLinkShared = featureFlagProvider.isFeatureFlagEnabled(for: .albumShareLink) ? album.isLinkShared : false
        
        if let coverNode = album.coverNode,
           let container = thumbnailUseCase.cachedThumbnailContainer(for: coverNode, type: .thumbnail) {
            thumbnailContainer = container
        } else {
            thumbnailContainer = ImageContainer(image: Image(Asset.Images.Album.placeholder.name), type: .placeholder)
        }
        
        configSelection()
        subscribeToEditMode()
    }
    
    @MainActor
    func loadAlbumThumbnail() async {
        guard let coverNode = album.coverNode,
              thumbnailContainer.type == .placeholder else {
            return
        }
        if !isLoading {
            isLoading.toggle()
        }
        await loadThumbnail(for: coverNode)
    }
    
    func onAlbumTap() {
        guard !album.systemAlbum else { return }
        isSelected.toggle()
        
        tracker.trackAnalyticsEvent(with: album.makeAlbumSelectedEvent(
            selectionType: isSelected ? .multiadd : .multiremove))
    }
    
    // MARK: Private
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailUseCase.loadThumbnailContainer(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = imageContainer
        isLoading = false
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .assign(to: &$isSelected)
    }
    
    private func subscribeToEditMode() {
        selection.$editMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.editMode = $0
            }
            .store(in: &subscriptions)
    }
}
