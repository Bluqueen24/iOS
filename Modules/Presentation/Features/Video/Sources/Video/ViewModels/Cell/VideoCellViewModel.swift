import MEGADomain
import MEGASwiftUI
import SwiftUI

final class VideoCellViewModel: ObservableObject {
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeEntity: NodeEntity
    private let onTapMoreOptions: (_ node: NodeEntity) -> Void
    
    @Published var previewEntity: VideoCellPreviewEntity
    
    init(thumbnailUseCase: some ThumbnailUseCaseProtocol, nodeEntity: NodeEntity, onTapMoreOptions: @escaping (_ node: NodeEntity) -> Void) {
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeEntity = nodeEntity
        self.onTapMoreOptions = onTapMoreOptions
        
        guard let cachedContainer = thumbnailUseCase.cachedThumbnailContainer(for: nodeEntity, type: .thumbnail) else {
            let placeholderContainer = ImageContainer(image: Image(systemName: "square.fill"), type: .placeholder)
            previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: placeholderContainer)
            return
        }
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: cachedContainer)
    }
    
    func attemptLoadThumbnail() async {
        guard
            previewEntity.imageContainer.type == .placeholder,
            let remoteContainer = await loadThumbnailContainerFromRemote() else {
            return
        }
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: remoteContainer)
    }
    
    func onTappedMoreOptions() {
        onTapMoreOptions(nodeEntity)
    }
    
    private func loadThumbnailContainerFromRemote() async -> (any ImageContaining)? {
        guard let container = try? await thumbnailUseCase.loadThumbnailContainer(for: nodeEntity, type: .thumbnail) else {
            return nil
        }
        return container
    }
}
