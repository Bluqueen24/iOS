import MEGADomain
import SwiftUI

public final class VideoRevampSyncModel {
    @Published public var videoRevampSortOrderType: SortOrderEntity?
    
    public init() {}
}

public class VideoRevampFactory {
    public static func makeTabContainerView(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) -> UIViewController {
        let videoListViewModel = VideoListViewModel(
            fileSearchUseCase: fileSearchUseCase,
            thumbnailUseCase: thumbnailUseCase,
            syncModel: syncModel
        )
        let view = TabContainerView(videoListViewModel: videoListViewModel, videoConfig: videoConfig, router: router)
        return UIHostingController(rootView: view)
    }
    
    public static func makeToolbarView(isDisabled: Bool, videoConfig: VideoConfig) -> UIViewController {
        let controller = UIHostingController(rootView: VideoToolbar(videoConfig: videoConfig, isDisabled: isDisabled))
        controller.view.backgroundColor = .clear
        return controller
    }
}
