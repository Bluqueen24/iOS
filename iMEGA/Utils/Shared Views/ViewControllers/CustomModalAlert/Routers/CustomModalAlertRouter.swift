import Foundation
import MEGADomain
import MEGAPresentation

@objc enum CustomModalAlertMode: Int {
    case storageEvent = 0
    case storageQuotaError
    case storageUploadQuotaError
    case transferDownloadQuotaError
    case businessGracePeriod
    case outgoingContactRequest
    case contactNotInMEGA
    case enableKeyRotation
    case upgradeSecurity
    case pendingUnverifiedOutShare
}

@objc class CustomModalAlertRouter: NSObject, Routing {
    
    private weak var presenter: UIViewController?
    
    internal var mode: CustomModalAlertMode
    
    private var chatId: ChatIdEntity?
    
    private var outShareEmail: String?
    
    private var transferQuotaDisplayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode?
    
    @objc init(_ mode: CustomModalAlertMode, presenter: UIViewController) {
        self.mode = mode
        self.presenter = presenter
    }
    
    init(_ mode: CustomModalAlertMode, presenter: UIViewController, chatId: ChatIdEntity) {
        self.mode = mode
        self.presenter = presenter
        self.chatId = chatId
    }
    
    init(_ mode: CustomModalAlertMode, presenter: UIViewController, outShareEmail: String) {
        self.mode = mode
        self.presenter = presenter
        self.outShareEmail = outShareEmail
    }
    
    init(_ mode: CustomModalAlertMode,
         presenter: UIViewController,
         transferQuotaDisplayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode) {
        self.mode = mode
        self.presenter = presenter
        self.transferQuotaDisplayMode = transferQuotaDisplayMode
    }
    
    func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        switch mode {
        case .storageQuotaError:
            customModalAlertVC.configureForStorageQuotaError(false)
            
        case .storageUploadQuotaError:
            customModalAlertVC.configureForStorageQuotaError(true)
            
        case .transferDownloadQuotaError:
            guard let transferDisplayMode = transferQuotaDisplayMode else { return customModalAlertVC }
            customModalAlertVC.configureForTransferQuotaError(for: transferDisplayMode)
             
        case .businessGracePeriod:
            customModalAlertVC.configureForBusinessGracePeriod()
            
        case .enableKeyRotation:
            guard let chatId else { return customModalAlertVC }
            customModalAlertVC.configureForEnableKeyRotation(in: chatId)
        
        case .upgradeSecurity:
            customModalAlertVC.configureForUpgradeSecurity()
        
        case .pendingUnverifiedOutShare:
            guard let outShareEmail else { return customModalAlertVC }
            customModalAlertVC.configureForPendingUnverifiedOutshare(for: outShareEmail)
            
        default: break
        }
        
        return customModalAlertVC
    }
    
    @objc func start() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if mode != .upgradeSecurity &&
            (visibleViewController is CustomModalAlertViewController ||
             visibleViewController is UpgradeTableViewController ||
             visibleViewController is ProductDetailViewController) {
            return
        }
        
        presenter?.present(build(), animated: true, completion: nil)
    }
}
