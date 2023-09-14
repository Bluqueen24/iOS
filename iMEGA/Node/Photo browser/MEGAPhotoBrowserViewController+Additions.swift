import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

extension MEGAPhotoBrowserViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(withNode: node)
    }
    
    func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func freeUpSpace(
        onImageViewCache cache: NSCache<NSNumber, UIScrollView>,
        imageViewsZoomCache: NSCache<NSNumber, NSNumber>,
        scrollView: UIScrollView
    ) {
        SVProgressHUD.show()
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        cache.removeAllObjects()
        imageViewsZoomCache.removeAllObjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SVProgressHUD.dismiss()
        }
    }
    
    @objc func rootPesentingViewController() -> UIViewController? {
        var curPresentingVC = presentingViewController
        var prePesentingVC: UIViewController?
        
        while curPresentingVC != nil {
            prePesentingVC = curPresentingVC
            curPresentingVC = curPresentingVC?.presentingViewController
        }
        
        return prePesentingVC
    }
    
    @objc func playCurrentVideo() async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        if node.mnz_isPlayable() {
            guard !MEGAChatSdk.sharedChatSdk.mnz_existsActiveCall else {
                Helper.cannotPlayContentDuringACallAlert()
                return
            }
            
            let controller = node.mnz_viewControllerForNode(
                inFolderLink: displayMode == .nodeInsideFolderLink,
                fileLink: nil)
            
            if let avViewController = controller as? MEGAAVViewController {
                let loadingController = MEGAAVViewControllerLoadingDecorator(decoratee: avViewController)
                loadingController.modalPresentationStyle = .overFullScreen
                present(loadingController, animated: true)
            } else {
                controller.modalPresentationStyle = .overFullScreen
                present(controller, animated: true)
            }
        } else {
            let controller = UIAlertController(
                title: Strings.Localizable.fileNotSupported,
                message: Strings.Localizable.messageFileNotSupported,
                preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel, handler: {[weak self] _ in
                self?.view.layoutIfNeeded()
                self?.reloadUI()
            }))
        }
    }
    
    @objc func configureMediaAttachment(forMessageId messageId: HandleEntity, inChatId chatId: HandleEntity, messagesIds: [HandleEntity]) {
        self.chatId = chatId
        self.messageId = messageId
        self.messagesIds = messagesIds
    }
    
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc func saveToPhotos(node: MEGANode) {
        permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
            guard let self else { return }
            if granted {
                let saveMediaUseCase = dataProvider.makeSaveMediaToPhotosUseCase(for: displayMode)
                
                let completionBlock: (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void = { result in
                    if case let .failure(error) = result, error != .cancelled {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.show(
                            Asset.Images.NodeActions.saveToPhotos.image,
                            status: error.localizedDescription
                        )
                    }
                }
                
                switch self.displayMode {
                case .chatAttachment, .chatSharedFiles:
                    saveMediaUseCase.saveToPhotosChatNode(handle: node.handle, messageId: self.messageId, chatId: self.chatId, completion: completionBlock)
                case .fileLink:
                    guard let linkUrl = URL(string: self.publicLink) else { return }
                    let fileLink = FileLinkEntity(linkURL: linkUrl)
                    saveMediaUseCase.saveToPhotos(fileLink: fileLink, completion: completionBlock)
                default:
                    Task { @MainActor in
                        do {
                            SnackBarRouter.shared.present(snackBar: SnackBar(message: Strings.Localizable.General.SaveToPhotos.started(1)))
                            try await saveMediaUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
                        } catch let error as SaveMediaToPhotosErrorEntity where error == .fileDownloadInProgress {
                            SnackBarRouter.shared.dismissSnackBar(immediate: true)
                            SnackBarRouter.shared.present(snackBar: SnackBar(message: error.localizedDescription))
                        } catch let error as SaveMediaToPhotosErrorEntity where error != .cancelled {
                            await SVProgressHUD.dismiss()
                            SVProgressHUD.show(
                                Asset.Images.NodeActions.saveToPhotos.image,
                                status: error.localizedDescription
                            )
                        } catch {
                            MEGALogError("[MEGAPhotoBrowserViewController] Error saving media nodes: \(error)")
                        }
                    }
                }
            } else {
                PermissionAlertRouter
                    .makeRouter(deviceHandler: permissionHandler)
                    .alertPhotosPermission()
            }
        }
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: publicLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func updateMessageId(to newIndex: UInt) {
        if messagesIds.isNotEmpty {
            guard let newMessageId = messagesIds[safe: Int(newIndex)] as? HandleEntity else { return }
            messageId = newMessageId
        }
    }

    @objc func openSlideShow() {
        SlideShowRouter(dataProvider: dataProvider, presenter: self).start()
    }
    
    @objc func isSlideShowEnabled() async -> Bool {
        switch displayMode {
        case .cloudDrive, .sharedItem, .albumLink:
            return await dataProvider.currentPhoto()?.name?.fileExtensionGroup.isImage == true
        default:
            return false
        }
    }
    
    @objc func activateSlideShowButton(barButtonItem: UIBarButtonItem?) {
        Task {
            if await isSlideShowEnabled() {
                barButtonItem?.image = UIImage(systemName: "play.rectangle")
                barButtonItem?.isEnabled = true
            } else {
                barButtonItem?.image = nil
                barButtonItem?.isEnabled = false
            }
        }
    }
    
    @objc func hideSlideShowButton(barButtonItem: UIBarButtonItem?) {
        barButtonItem?.image = nil
        barButtonItem?.isEnabled = false
    }
    
    @objc func viewNodeInFolder(_ node: MEGANode) {
        guard let parentNode = MEGASdk.sharedSdk.node(forHandle: node.parentHandle),
              parentNode.isFolder() else {
            return
        }
        openFolderNode(parentNode, isFromViewInFolder: true)
    }
    
    func openFolderNode(_ node: MEGANode, isFromViewInFolder: Bool) {
        let cloudStoryboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let cloudDriveViewController = cloudStoryboard.instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController else { return }
        cloudDriveViewController.parentNode = node
        cloudDriveViewController.isFromViewInFolder = isFromViewInFolder
        
        if node.mnz_isInRubbishBin() && isFromViewInFolder {
            cloudDriveViewController.displayMode = .rubbishBin
        }
        
        let navigationContorller = MEGANavigationController(rootViewController: cloudDriveViewController)
        present(navigationContorller, animated: true)
    }
    
    @objc func clearNodeOnTransfers(_ node: MEGANode) {
        if let navController = presentingViewController as? MEGANavigationController,
           let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        } else if let tabBarController = presentingViewController as? MainTabBarController,
                  let navController = tabBarController.selectedViewController as? MEGANavigationController,
                  let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        }
    }
    
    @objc func showRemoveLinkWarning(_ node: MEGANode) {
        ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        }).start()
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: self,
                      nodes: nodes).start()
    }
}

extension MEGAPhotoBrowserViewController: MEGAPhotoBrowserPickerDelegate {
    public func updateCurrentIndex(to newIndex: UInt) {
        if dataProvider.shouldUpdateCurrentIndex(toIndex: Int(newIndex)) {
            dataProvider.currentIndex = Int(newIndex)
            needsReload = true
            updateMessageId(to: newIndex)
        }
    }
}

extension MEGAPhotoBrowserViewController {
    
    @objc func loadNode(for index: Int) {
        Task {
            guard let node = await dataProvider.photoNode(at: index) else {
                return
            }
            configureNode(intoImage: node, nodeIndex: UInt(index))
        }
    }
}

extension MEGAPhotoBrowserViewController {
    static func photoBrowser(currentPhoto: NodeEntity, allPhotos: [NodeEntity],
                             displayMode: DisplayMode = .cloudDrive) -> MEGAPhotoBrowserViewController {
        
        let sdk: MEGASdk
        let nodeProvider: any MEGANodeProviderProtocol
        switch displayMode {
        case .nodeInsideFolderLink:
            sdk = .sharedFolderLink
            nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        case .albumLink:
            sdk = .shared
            nodeProvider = PublicAlbumNodeProvider.shared
        default:
            sdk = .shared
            nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        }
        
        let browser = MEGAPhotoBrowserViewController.photoBrowser(
            with: PhotoBrowserDataProvider(
                currentPhoto: currentPhoto,
                allPhotos: allPhotos,
                sdk: sdk,
                nodeProvider: nodeProvider),
            api: sdk,
            displayMode: displayMode
        )
        browser.needsReload = true
        return browser
    }
}

extension MEGAPhotoBrowserViewController {
    @objc func updateProviderNodeEntities(nodes: [MEGANode]) {
        DispatchQueue.main.async {
            self.dataProvider.convertToNodeEntities(from: nodes)
        }
    }
    
    @objc func reloadTitle() async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        let subtitle: String?
        switch displayMode {
        case .fileLink:
            subtitle = Strings.Localizable.fileLink
        case .chatAttachment where node.creationTime != nil:
            guard let creationTime = node.creationTime else {
                subtitle = nil
                break
            }
            subtitle = self.subtitle(fromDate: creationTime)
        default:
            let formattedText = Strings.Localizable.Media.Photo.Browser.indexOfTotalFiles(dataProvider.count)
            subtitle = formattedText.replacingOccurrences(
                of: "[A]",
                with: String(format: "%lu", dataProvider.currentIndex + 1))
        }
        
        let rootView: NavigationTitleView?
        if let name = node.name {
            rootView = .init(title: name, subtitle: subtitle)
        } else if let subtitle {
            rootView = .init(title: subtitle)
        } else {
            rootView = nil
        }
             
        guard let rootView else {
            navigationItem.titleView = nil
            return
        }
        
        let hostController = UIHostingController(rootView: rootView)
        let titleView = hostController.view
        titleView?.backgroundColor = .clear
        navigationItem.titleView = titleView
        navigationItem.titleView?.sizeToFit()
    }
}

// MARK: - OnNodesUpdate
extension MEGAPhotoBrowserViewController {
    @objc func handleNodeUpdates(fromNodes nodeList: MEGANodeList?) {
        guard let nodeList, shouldUpdateNodes(nodes: nodeList) else { return }
        
        Task { [weak self] in
            guard let self else { return }
            let remainingNodesToUpdateCount = await dataProvider.removePhotos(in: nodeList)
            
            if remainingNodesToUpdateCount == 0 {
                guard let currentNode = await dataProvider.currentPhoto() else { return }
                let removedNodes = nodeList.toNodeEntities().removedChangeTypeNodes()
                
                guard removedNodes.isNotEmpty,
                      removedNodes.first(where: { $0.handle == currentNode.handle }) != nil else { return }
                dismiss(animated: true)
            } else {
                dataProvider.updatePhotos(in: nodeList)
                reloadUI()
            }
        }
    }
    
    private func shouldUpdateNodes(nodes: MEGANodeList) -> Bool {
        let nodeEntities = nodes.toNodeEntities()
        guard nodeEntities.isNotEmpty else { return false }
        return nodeEntities.removedChangeTypeNodes().isNotEmpty ||
                nodeEntities.hasModifiedAttributes() ||
                nodeEntities.hasModifiedPublicLink() ||
                nodeEntities.hasModifiedFavourites()
    }
}

// MARK: - IBActions
extension MEGAPhotoBrowserViewController {
    
    @objc func didPressActionsButton(_ sender: UIBarButtonItem, delegate: (any NodeActionViewControllerDelegate)?) async {
        guard let node = await dataProvider.currentPhoto(),
              let delegate else {
            return
        }
        
        let isBackUpNode = BackupsOCWrapper().isBackupNode(node)
        let controller = NodeActionViewController(node: node, delegate: delegate, displayMode: displayMode, isInVersionsView: isPreviewingVersion(), isBackupNode: isBackUpNode, sender: sender)
    
        present(controller, animated: true)
    }
    
    @objc func didPressLeftToolbarButton(_ sender: UIBarButtonItem) async {
        
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            node.mnz_fileLinkImport(from: self, isFolderLink: false)
        default:
            didPressAllMediasButton(sender)
        }
    }
    
    @objc func didPressRightToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            shareFileLink()
        case .albumLink:
            openSlideShow()
        default:
            exportFile(from: node, sender: sender)
        }
    }
    
    @objc func didPressExportFile(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            exportFile(from: node, sender: sender)
        default:
            exportMessageFile(from: node, messageId: messageId, chatId: chatId, sender: sender)
        }
    }
    
    @objc func didPressCenterToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            saveToPhotos(node: node)
        case .sharedItem, .cloudDrive:
            openSlideShow()
        default:
            break
        }
    }
}
