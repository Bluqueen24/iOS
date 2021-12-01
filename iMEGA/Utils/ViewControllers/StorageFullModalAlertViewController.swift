import UIKit

class StorageFullModalAlertViewController: CustomModalAlertViewController {
    
    
    private let limitedSpace = 100 * 1024 * 1024
    private let duration = 2
    
    private var requiredStorage: Int64 = 100 * 1024 * 1024
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "CustomModalAlertViewController", bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        configureView()
        super.viewDidLoad()
    }
    
    func configureView() {
        image = UIImage(named: "deviceStorageAlmostFull")
        viewTitle = Strings.Localizable.deviceStorageAlmostFull
        detail = Strings.Localizable.MEGANeedsAMinimumOf
            .FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery
            .youCanAlsoManageWhatMEGAStoresOnYourDevice(Helper.memoryStyleString(fromByteCount: requiredStorage))

        firstButtonTitle = Strings.Localizable.manage

        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                let fileManagementVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "FileManagementTableViewControllerID")
                UIApplication.mnz_visibleViewController().navigationController?.pushViewController(fileManagementVC, animated: true)
            })
        }
        
        dismissButtonTitle = Strings.Localizable.notNow

        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "MEGAStorageFullNotification")
            })
        }
    }
    
    @objc func show() {
        show(requiredStorage: requiredStorage)
    }
    
    @objc func show(requiredStorage: Int64) {
        modalPresentationStyle = .overFullScreen;
        self.requiredStorage = requiredStorage
        guard !UIApplication.mnz_visibleViewController().isKind(of: StorageFullModalAlertViewController.self) else {
            return
        }
        UIApplication.mnz_visibleViewController().present(self, animated: true, completion: nil)
    }
    
    @objc func showStorageAlertIfNeeded() {
        let storageDate = Date(timeIntervalSince1970: TimeInterval(UserDefaults.standard.double(forKey: "MEGAStorageFullNotification"))) as NSDate
        
        guard FileManager.default.mnz_fileSystemFreeSize < limitedSpace,
            storageDate.daysEarlierThan(Date()) < duration else {
            return
        }
        
        show()
    }
}
