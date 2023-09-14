import Combine
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

// MARK: - Context Menu
extension PhotoAlbumContainerViewController {
    func updateBarButtons() {
        if isEditing {
            navigationItem.setRightBarButton(cancelBarButton, animated: true)
            navigationItem.setLeftBarButton(nil, animated: true)
            showToolbar()
        } else {
            navigationItem.setRightBarButton(selectBarButton, animated: false)
            navigationItem.setLeftBarButton(leftBarButton, animated: true)
            hideToolbar()
        }
    }
    
    @objc func toggleEditing(sender: UIBarButtonItem) {
        guard !viewModel.disableSelectBarButton else { return }
        
        isEditing = !isEditing
        viewModel.editMode = isEditing ? .active : .inactive
        updateBarButtons()
    }
    
    var selectBarButton: UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    var cancelBarButton: UIBarButtonItem {
        let cancelBarButton = UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
        return cancelBarButton
    }
    
    func updateRightBarButton() {
        guard pageTabViewModel.selectedTab == .album else {
            navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        navigationItem.setRightBarButtonItems(viewModel.shouldShowSelectBarButton ? [selectBarButton] : nil, animated: false)
    }
}
