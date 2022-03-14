import UIKit

final class ___VARIABLE_sceneName:identifier___ViewRouter: ___VARIABLE_sceneName:identifier___ViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
//    private weak var navigationController: UINavigationController?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }

//    init(navigationController: UINavigationController?) {
//        self.navigationController = navigationController
//    }
//
    func build() -> UIViewController {
        // Storyboard
        let vm = ___VARIABLE_sceneName:identifier___ViewModel(router: self)
        let vc = UIStoryboard(name: "", bundle: nil).instantiateViewController(withIdentifier: String(describing: ___VARIABLE_sceneName:identifier___ViewController.self)) as! ___VARIABLE_sceneName:identifier___ViewController
        vc.viewModel = vm
        
        // Xib
//        let vm = ___VARIABLE_sceneName:identifier___ViewModel(router: self)
//        let vc = ___VARIABLE_sceneName:identifier___ViewController(viewModel: vm)

        baseViewController = vc
        return vc
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: nil)
        
//      Alternative:
//        navigationController?.pushViewController(build(), animated: true)
    }
    
    // MARK: - UI Actions
}
