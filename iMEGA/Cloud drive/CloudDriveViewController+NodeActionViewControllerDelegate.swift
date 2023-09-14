import MEGADomain
import MEGASDKRepo

extension CloudDriveViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        switch action {
        case .download:
            download(nodes)
            setEditMode(false)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            prepareToMoveNodes(nodes)
        case .moveToRubbishBin:
            guard let deleteBarButton = sender as? UIBarButtonItem else { return }
            deleteAction(sender: deleteBarButton)
        case .exportFile:
            let entityNodes = nodes.toNodeEntities()
            ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
            setEditMode(false)
        case .shareFolder:
            viewModel.openShareFolderDialog(forNodes: nodes)
        case .shareLink, .manageLink:
            presentGetLink(for: nodes)
            setEditMode(false)
        case .sendToChat:
            showSendToChat(nodes)
            setEditMode(false)
        case .removeLink:
            ActionWarningViewRouter(presenter: self, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: { [weak self] result in
                self?.setEditMode(false)
                self?.showRemoveLinkResultMessage(result)
            }).start()
        case .saveToPhotos:
            saveToPhotos(nodes: nodes.toNodeEntities())
        default:
            break
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        resetEditingModeIfNeeded()
        
        switch action {
        case .download:
            download([node])
        case .exportFile:
            exportFile(from: node, sender: sender)
        case .copy:
            showBrowserNavigation(for: [node], action: .copy)
        case .move, .restoreBackup:
            showBrowserNavigation(for: [node], action: .move)
        case .info:
            showNodeInfo(node)
        case .favourite:
            wasSelectingFavoriteUnfavoriteNodeActionOption = true
            MEGASdk.shared.setNodeFavourite(node, favourite: !node.isFavourite)
        case .label:
            node.mnz_labelActionSheet(in: self)
        case .leaveSharing:
            node.mnz_leaveSharing(in: self)
        case .rename:
            node.mnz_renameNode(in: self)
        case .removeLink:
            ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: { [weak self] result in
                self?.showRemoveLinkResultMessage(result)
            }).start()
        case .moveToRubbishBin:
            moveToRubbishBin(for: node)
        case .remove:
            node.mnz_remove(in: self) { [weak self] shouldRemove in
                if shouldRemove {
                    if node.mnz_isPlaying() {
                        AudioPlayerManager.shared.closePlayer()
                    } else if node.isFolder() && self?.parentNode?.handle == node.handle {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        case .removeSharing:
            node.mnz_removeSharing()
        case .viewVersions:
            node.mnz_showVersions(in: self)
        case .restore:
            node.mnz_restore()
            
            if node.isFolder() && parentNode?.handle == node.handle {
                navigationController?.popViewController(animated: true)
            }
        case .saveToPhotos:
            saveToPhotos(nodes: [node.toNodeEntity()])
        case .manageShare:
            BackupNodesValidator(presenter: self, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded { [weak self] in
                self?.manageShare(node)
            }
        case .shareFolder:
            viewModel.openShareFolderDialog(forNodes: [node])
        case .manageLink, .shareLink:
            presentGetLink(for: [node])
        case .sendToChat:
            showSendToChat([node])
        case .editTextFile:
            node.mnz_editTextFile(in: self)
        case .disputeTakedown:
            NSURL(string: MEGADisputeURL)?.mnz_presentSafariViewController()
        default: break
        }
    }
    
    private func resetEditingModeIfNeeded() {
        let isStillInEditingThumbnailState = (!isListViewModeSelected()) && (cdCollectionView?.collectionView?.allowsMultipleSelection == true)
        if isStillInEditingThumbnailState {
            setEditMode(false)
        }
    }
    
    func download(_ nodes: [MEGANode]) {
        let transfers = nodes.map { CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
    }
    
    func manageShare(_ node: MEGANode) {
        guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(identifier: "ContactsViewControllerID") as? ContactsViewController else { return }
        contactsVC.node = node
        contactsVC.contactsMode = .folderSharedWith
        navigationController?.pushViewController(contactsVC, animated: true)
    }
    
    private func saveToPhotos(nodes: [NodeEntity]) {
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdk.shared), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        Task { @MainActor in
            do {
                try await saveMediaUseCase.saveToPhotos(nodes: nodes)
            } catch {
                if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        Asset.Images.NodeActions.saveToPhotos.image,
                        status: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func showRemoveLinkResultMessage(_ result: Result<String, RemoveLinkErrorEntity>) {
        switch result {
        case .success(let message):
            SVProgressHUD.showSuccess(withStatus: message)
        case .failure:
            SVProgressHUD.dismiss()
        }
    }
}
