import Foundation

final class FolderLinkCollectionViewDiffableDataSource {
    private var dataSource: UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>?
    private weak var collectionView: UICollectionView?
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    func load(data: [ThumbnailSection: [MEGANode]], keys: [ThumbnailSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<ThumbnailSection, MEGANode>()
        keys.forEach { key in
            snapshot.appendSections([key])
            snapshot.appendItems(data[key] ?? [])
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    func reload(nodes: [MEGANode]) {
        guard var newSnapshot = dataSource?.snapshot() else { return }
        newSnapshot.reloadItems(nodes)
        dataSource?.apply(newSnapshot)
    }

    func configureDataSource() {
        guard let collectionView = collectionView else { return }

        dataSource = UICollectionViewDiffableDataSource<ThumbnailSection, MEGANode>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, node: MEGANode) -> UICollectionViewCell? in
            let cellId = indexPath.section == 1 ? "NodeCollectionFileID" : "NodeCollectionFolderID"
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? NodeCollectionViewCell else {
                fatalError("Could not instantiate NodeCollectionViewCell or Node at index")
            }
            
            cell.configureCell(for: node, api:MEGASdkManager.sharedMEGASdkFolder())
            cell.selectImageView?.isHidden = !collectionView.allowsMultipleSelection
            cell.moreButton?.isHidden = collectionView.allowsMultipleSelection
            
            if node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil {
                cell.downloadedImageView?.isHidden = false
            } else {
                cell.downloadedImageView?.isHidden = true
            }
            
            return cell
        }
    }
}
