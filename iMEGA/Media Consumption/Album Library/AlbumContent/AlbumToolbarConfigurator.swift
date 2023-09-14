final class AlbumToolbarConfigurator: ExplorerToolbarConfigurator {
    let favouriteAction: ButtonAction
    let removeToRubbishBinAction: ButtonAction
    let exportAction: ButtonAction
    let sendToChatAction: ButtonAction
    let albumType: AlbumType
    
    private var favouriteItemImage: ImageAsset {
        albumType == .favourite ? Asset.Images.NodeActions.removeFavourite :
        Asset.Images.NodeActions.favourite
    }
    
    lazy var favouriteItem = UIBarButtonItem(
        image: favouriteItemImage.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var sendToChatItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.sendToChat.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var removeToRubbishBinItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.rubbishBin.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    init(
        downloadAction: @escaping ButtonAction,
        shareLinkAction: @escaping ButtonAction,
        moveAction: @escaping ButtonAction,
        copyAction: @escaping ButtonAction,
        deleteAction: @escaping ButtonAction,
        favouriteAction: @escaping ButtonAction,
        removeToRubbishBinAction: @escaping ButtonAction,
        exportAction: @escaping ButtonAction,
        sendToChatAction: @escaping ButtonAction,
        moreAction: @escaping ButtonAction,
        albumType: AlbumType
    ) {
        self.favouriteAction = favouriteAction
        self.removeToRubbishBinAction = removeToRubbishBinAction
        self.exportAction = exportAction
        self.sendToChatAction = sendToChatAction
        self.albumType = albumType
        
        super.init(
            downloadAction: downloadAction,
            shareLinkAction: shareLinkAction,
            moveAction: moveAction,
            copyAction: copyAction,
            deleteAction: deleteAction,
            moreAction: moreAction
        )
    }
    
    override func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case downloadItem:
            super.downloadAction(barButtonItem)
        case shareLinkItem:
            super.shareLinkAction(barButtonItem)
        case favouriteItem:
            favouriteAction(barButtonItem)
        case removeToRubbishBinItem:
            removeToRubbishBinAction(barButtonItem)
        case exportItem:
            exportAction(barButtonItem)
        case sendToChatItem:
            sendToChatAction(barButtonItem)
        case moreItem:
            super.moreAction(barButtonItem)
        default:
            super.buttonPressed(barButtonItem)
        }
    }
    
    override func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        var barButtonItems = [
            downloadItem,
            flexibleItem,
            shareLinkItem,
            flexibleItem,
            exportItem,
            flexibleItem,
            sendToChatItem
        ]
        if albumType == .favourite {
            barButtonItems.append(contentsOf: [
                flexibleItem,
                favouriteItem
            ])
        } else if albumType == .user {
            barButtonItems.append(contentsOf: [
                flexibleItem,
                removeToRubbishBinItem
            ])
        }

        return enable(
            nodes?.isNotEmpty == true,
            hasDisputedNodes: nodes?.contains(where: { $0.isTakenDown() }) == true,
            barButtonItems: barButtonItems)
    }
}
