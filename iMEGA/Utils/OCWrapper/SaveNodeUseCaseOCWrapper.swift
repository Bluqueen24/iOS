import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo

@objc class SaveNodeUseCaseOCWrapper: NSObject {
    let saveNodeUseCase = SaveNodeUseCase(
        offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdk.shared),
        fileCacheRepository: FileCacheRepository.newRepo,
        nodeRepository: NodeRepository.newRepo,
        photosLibraryRepository: PhotosLibraryRepository.newRepo,
        mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
        preferenceUseCase: PreferenceUseCase.default,
        transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.shared))
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        saveNodeUseCase.saveNode(from: transfer.toTransferEntity()) { result in
            switch result {
            case .success(let savedToPhotos):
                let transferInventoryUseCase = TransferInventoryUseCase(
                    transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.shared), fileSystemRepository: FileSystemRepository.newRepo)
                let anyPendingSavePhotosTransfer = transferInventoryUseCase.saveToPhotosTransfers(filteringUserTransfer: true)?.isNotEmpty ?? false
                if savedToPhotos, !anyPendingSavePhotosTransfer {
                    SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savedToPhotos)
                }
            case .failure(let error):
                switch error {
                case .videoNotSaved, .imageNotSaved:
                    SVProgressHUD.showError(withStatus: Strings.Localizable.couldNotSaveItem)
                default:
                    SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
                }
            }
        }
    }
}
