extension CloudDriveViewController {
    @IBAction func deleteAction(sender: UIBarButtonItem) {
        guard let selectedNodes = selectedNodesArray as? [MEGANode] else {
            return
        }
        
        switch displayMode {
        case .cloudDrive:
            checkIfCameraUploadPromptIsNeeded { [weak self] shouldPrompt in
                DispatchQueue.main.async {
                    if shouldPrompt {
                        self?.promptCameraUploadFolderDeletion {
                            self?.deleteSelectedNodes()
                        }
                    } else {
                        self?.deleteSelectedNodes()
                    }
                }
            }
        case .rubbishBin:
            confirmDeleteActionFiles(selectedNodes.contentCounts().fileCount,
                                     andFolders: selectedNodes.contentCounts().folderCount)
        default: break
        }
    }
    
    @objc func moveToRubbishBin(for node: MEGANode) {
        guard let rubbish = MEGASdk.shared.rubbishNode else {
            self.dismiss(animated: true)
            return
        }
        
        CameraUploadNodeAccess.shared.loadNode { [weak self] (cuNode, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard let cuNode = cuNode else {
                    node.mnz_askToMoveToTheRubbishBin(in: self)
                    return
                }
                
                if cuNode.isDescendant(of: node, in: .shared) {
                    self.promptCameraUploadFolderDeletion {
                        let delegate = MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: 0, folders: 1) {
                            self.dismiss(animated: true)
                        }
                        MEGASdk.shared.move(node, newParent: rubbish, delegate: delegate)
                    }
                } else {
                    node.mnz_askToMoveToTheRubbishBin(in: self)
                }
            }
        }
    }
    
    private func deleteSelectedNodes() {
        guard let selectedNodes = selectedNodesArray as? [MEGANode],
              let rubbish = MEGASdk.shared.rubbishNode else {
            return
        }
        
        let delegate = MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: selectedNodes.contentCounts().fileCount,
                                               folders: selectedNodes.contentCounts().folderCount) {
            self.setEditMode(false)
        }
        
        for node in selectedNodes {
            MEGASdk.shared.move(node, newParent: rubbish, delegate: delegate)
        }
    }
    
    private func checkIfCameraUploadPromptIsNeeded(completion: @escaping (Bool) -> Void) {
        guard let selectedNodes = selectedNodesArray as? [MEGANode],
              CameraUploadManager.isCameraUploadEnabled else {
            completion(false)
            return
        }
        
        CameraUploadNodeAccess.shared.loadNode { node, _ in
            guard let cuNode = node else { return }
            
            let isSelected = selectedNodes.contains {
                cuNode.isDescendant(of: $0, in: .shared)
            }
            
            completion(isSelected)
        }
    }
    
    private func promptCameraUploadFolderDeletion(deleteHandler: @escaping () -> Void, cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: Strings.Localizable.General.MenuAction.moveToRubbishBin,
                                      message: Strings.Localizable.areYouSureYouWantToMoveCameraUploadsFolderToRubbishBinIfSoANewFolderWillBeAutoGeneratedForCameraUploads,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: Strings.Localizable.cancel, style: .cancel) { _ in
            cancelHandler?()
        })
        
        alert.addAction(.init(title: Strings.Localizable.ok, style: .default) { _ in
            deleteHandler()
        })
        
        self.present(alert, animated: true)
    }
}
