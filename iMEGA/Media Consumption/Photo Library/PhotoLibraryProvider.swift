import Foundation
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
protocol PhotoLibraryProvider: UIViewController {
    var photoLibraryContentViewModel: PhotoLibraryContentViewModel { get }
    
    func configPhotoLibraryView(in container: UIView, onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?)
    func updatePhotoLibrary(by nodes: [NodeEntity], withSortType type: SortOrderType)
    func hideNavigationEditBarButton(_ hide: Bool)
    func enablePhotoLibraryEditMode(_ enable: Bool)
    func configPhotoLibrarySelectAll()
    func updateNavigationTitle(withSelectedPhotoCount count: Int)
    func disablePhotoSelection(_ disable: Bool)
}

extension PhotoLibraryProvider {
    func configPhotoLibraryView(in container: UIView, onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)? = nil) {
        let content = PhotoLibraryContentView(
            viewModel: photoLibraryContentViewModel,
            router: PhotoLibraryContentViewRouter(contentMode: photoLibraryContentViewModel.contentMode),
            onFilterUpdate: onFilterUpdate
        )
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        host.didMove(toParent: self)
    }
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func configPhotoLibrarySelectAll() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func updateNavigationTitle(withSelectedPhotoCount count: Int) {
        var message = ""
        
        if count == 0 {
            message = Strings.Localizable.selectTitle
        } else {
            message = Strings.Localizable.General.Format.itemsSelected(count)
        }
        
        navigationItem.title = message
    }
    
    func updatePhotoLibrary(by nodes: [NodeEntity], withSortType type: SortOrderType = .newest) {
        guard let host = children.first(where: { $0 is UIHostingController<PhotoLibraryContentView> }) else {
            return
        }
        
        Task {
            let photoLibrary = await load(by: nodes, withSortType: type)
            
            host.view.isHidden = photoLibrary.isEmpty
            photoLibraryContentViewModel.library = photoLibrary
            
            hideNavigationEditBarButton(photoLibrary.isEmpty)
        }
    }
    
    func disablePhotoSelection(_ disable: Bool) {
        photoLibraryContentViewModel.selection.isSelectionDisabled = disable
    }
    
    // MARK: - Private
    
    private func load(by nodes: [NodeEntity], withSortType type: SortOrderType) async -> PhotoLibrary {
        let mapper = PhotoLibraryMapper()
        let lib = await mapper.buildPhotoLibrary(with: nodes, withSortType: type)
        
        return lib
    }
}
