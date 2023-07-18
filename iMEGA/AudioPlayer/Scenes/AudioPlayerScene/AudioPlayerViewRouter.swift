import Foundation
import MEGADomain
import MEGAPresentation

final class AudioPlayerViewRouter: NSObject, AudioPlayerViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private var configEntity: AudioPlayerConfigEntity
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    
    init(configEntity: AudioPlayerConfigEntity, presenter: UIViewController) {
        self.configEntity = configEntity
        self.presenter = presenter
        super.init()
    }
    
    func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil)
            .instantiateViewController(withIdentifier: "AudioPlayerViewControllerID") as! AudioPlayerViewController
        
        if configEntity.playerType == .offline {
            vc.viewModel = AudioPlayerViewModel(
                configEntity: configEntity,
                router: self,
                offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: OfflineInfoRepository()),
                playbackContinuationUseCase: DIContainer.playbackContinuationUseCase
            )
        } else {
            vc.viewModel = AudioPlayerViewModel(
                configEntity: configEntity,
                router: self,
                nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: NodeInfoRepository()),
                streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: StreamingInfoRepository()),
                playbackContinuationUseCase: DIContainer.playbackContinuationUseCase
            )
        }

        baseViewController = vc
        
        switch configEntity.nodeOriginType {
        case .folderLink, .chat:
            nodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
                viewController: vc,
                isNodeFromFolderLink: configEntity.isFolderLink,
                messageId: configEntity.messageId,
                chatId: configEntity.chatId
            )
        case .fileLink:
            fileLinkActionViewControllerDelegate = FileLinkActionViewControllerDelegate(
                link: configEntity.fileLink ?? "",
                viewController: vc
            )
        case .unknown:
            break
        }
        
        return configEntity.fileLink != nil ? MEGANavigationController(rootViewController: vc) : vc
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToPlaylist() {
        guard let presenter = self.baseViewController else { return }
        AudioPlaylistViewRouter(configEntity: AudioPlayerConfigEntity(parentNode: configEntity.node?.parent, playerHandler: configEntity.playerHandler), presenter: presenter).start()
    }
    
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool) {
        guard let presenter = presenter else { return }
        
        configEntity.playerHandler.initMiniPlayer(node: node, fileLink: configEntity.fileLink, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func showMiniPlayer(file: String, shouldReload: Bool) {
        guard let presenter = presenter else { return }
        
        configEntity.playerHandler.initMiniPlayer(node: nil, fileLink: file, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func importNode(_ node: MEGANode) {
        fileLinkActionViewControllerDelegate?.importNode(node)
    }
    
    func share(sender: UIBarButtonItem?) {
        fileLinkActionViewControllerDelegate?.shareLink(sender: sender)
    }
    
    func sendToChat() {
        fileLinkActionViewControllerDelegate?.sendToChat()
    }
    
    func showAction(for node: MEGANode, sender: Any) {
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: self,
            displayMode: displayMode,
            isInVersionsView: isPlayingFromVersionView(),
            isBackupNode: isBackupNode,
            sender: sender)
        
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    private func isPlayingFromVersionView() -> Bool {
        return presenter?.isKind(of: NodeVersionsViewController.self) == true
    }
}

extension AudioPlayerViewRouter: NodeActionViewControllerDelegate {

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch configEntity.nodeOriginType {
        case .folderLink, .chat:
            nodeActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        case .fileLink:
            fileLinkActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        case .unknown:
            break
        }
    }
}
