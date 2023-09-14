import Foundation
import MEGADomain
import MEGAL10n
import MEGASDKRepo

final class FileLinkActionViewControllerDelegate: NSObject, NodeActionViewControllerDelegate {
    
    private weak var viewController: UIViewController?
    private let link: String

    init(link: String, viewController: UIViewController) {
        self.link = link
        self.viewController = viewController
    }
    
    private func download(node: MEGANode) {
        guard let vc = viewController, let linkUrl = URL(string: link) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: vc).start()
    }
    
    func importNode(_ node: MEGANode) {
        guard let vc = viewController else { return }
        
        node.mnz_fileLinkImport(from: vc, isFolderLink: false)
    }
    
    func sendToChat() {
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle(for: SendToViewController.self))
        if let navController = storyboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
           let sendToViewController = navController.viewControllers.first as? SendToViewController {
            sendToViewController.sendMode = .fileAndFolderLink
            sendToViewController.sendToViewControllerDelegate = self
            
            viewController?.present(navController, animated: true)
        }
    }
    
    func shareLink(sender: UIBarButtonItem?) {
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        viewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    private func saveToPhotos(node: MEGANode) {
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        let saveMediaToPhotosUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: .shared), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)

        Task { @MainActor in
            do {
                try await saveMediaToPhotosUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
            } catch {
                if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                    AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo).sendAnalyticsEvent(.download(.saveToPhotos))
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        Asset.Images.NodeActions.saveToPhotos.image,
                        status: error.localizedDescription
                    )
                }
            }
            
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .download: download(node: node)
        case .import: importNode(node)
        case .sendToChat: sendToChat()
        case .shareLink: shareLink(sender: sender as? UIBarButtonItem)
        case .saveToPhotos: saveToPhotos(node: node)
        default:
            break
        }
    }
}

extension FileLinkActionViewControllerDelegate: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController!, toChats chats: [MEGAChatListItem]!, andUsers users: [MEGAUser]!) {
        viewController.dismiss(animated: true, completion: nil)
        
        chats.forEach {
            MEGAChatSdk.shared.sendMessage(toChat: $0.chatId, message: link)
        }
        
        users.forEach {
            let chatRoom = MEGAChatSdk.shared.chatRoom(byUser: $0.handle)
            if chatRoom != nil {
                guard let chatId = chatRoom?.chatId else {
                    return
                }
                MEGAChatSdk.shared.sendMessage(toChat: chatId, message: link)
            } else {
                MEGALogDebug("There is not a chat with %@, create the chat and send message", $0.email)
                MEGAChatSdk.shared.mnz_createChatRoom(userHandle: $0.handle, completion: {
                    MEGAChatSdk.shared.sendMessage(toChat: $0.chatId, message: self.link)
                })
            }
        }
        
        let totalCount = chats.count + users.count
        let message = totalCount == 1 ? Strings.Localizable.fileSentToChat : Strings.Localizable.fileSentToXChats(totalCount)
        SVProgressHUD.showSuccess(withStatus: message)
    }
}
