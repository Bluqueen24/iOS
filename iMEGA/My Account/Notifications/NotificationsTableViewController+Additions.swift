import MEGADomain
import MEGAL10n

extension NotificationsTableViewController {
    
    @objc func contentForTakedownReinstatedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdk.shared.node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.folder(nodeName))
        default: return nil
        }
    }
    
    @objc func contentForTakedownPubliclySharedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdk.shared.node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.folder(nodeName))
        default: return nil
        }
    }
    
    private func contentMessageAttributedString(withNodeName nodeName: String,
                                                nodeFont: UIFont,
                                                message: String) -> NSAttributedString? {
        let contentAttributedText = NSMutableAttributedString(string: message)
        if let nodeNameRange = message.range(of: nodeName) {
            contentAttributedText.addAttributes([.font: nodeFont], range: NSRange(nodeNameRange, in: message))
        }
        return contentAttributedText
    }
    
    @objc func logUserAlertsStatus(_ userAlerts: [MEGAUserAlert]) {
        let alertsString = userAlerts.map { alert in
            "\(alert.type.rawValue) - \(alert.typeString ?? "None") - \(alert.string(at: 0) ?? "None")"
        }.joined(separator: "\n")
        
        MEGALogDebug("[Notifications] \(userAlerts.count)\n\(alertsString)")
    }
    
    @objc func showUpgradePlanView() {
        guard let navigationController else { return }
        UpgradeAccountRouter().pushUpgradeTVC(navigationController: navigationController)
    }
}
