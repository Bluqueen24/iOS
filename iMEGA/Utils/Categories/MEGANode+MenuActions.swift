extension MEGANode {
    // MARK: - Import
    func openBrowserToImport(in viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController
        else { return }
        browserVC.selectedNodesArray = [self]
        browserVC.browserAction = .import
        let browserNC = MEGANavigationController(rootViewController: browserVC)
        browserNC.setToolbarHidden(false, animated: false)
        viewController.present(browserNC, animated: true, completion: nil)
    }
    
}
