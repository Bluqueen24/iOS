import MEGADomain
import MEGAL10n

extension NodeVersionsViewController {
    @objc func setToolbarActionsEnabled(_ boolValue: Bool) {
        let selectedNodesArray = self.selectedNodesArray as? [MEGANode] ?? []
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        let nodeAccessLevel = MEGASdk.shared.accessLevel(for: node).rawValue
        
        downloadBarButtonItem.isEnabled = selectedNodesArray.count == 1 && boolValue
        revertBarButtonItem.isEnabled = !isBackupNode && selectedNodesArray.count == 1 && selectedNodesArray.first?.handle != node.handle && nodeAccessLevel >= MEGAShareType.accessReadWrite.rawValue && boolValue
        removeBarButtonItem.isEnabled = nodeAccessLevel >= MEGAShareType.accessFull.rawValue && boolValue
    }
    
    @objc func configureToolbarItems() {
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        
        setToolbarItems(isBackupNode ? [downloadBarButtonItem, flexibleItem, removeBarButtonItem] : [downloadBarButtonItem, flexibleItem, revertBarButtonItem, flexibleItem, removeBarButtonItem], animated: true)
    }
    
    @objc func selectedCountTitle() -> String {
        guard let selectedCount = selectedNodesArray?.count,
              selectedCount > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
}
