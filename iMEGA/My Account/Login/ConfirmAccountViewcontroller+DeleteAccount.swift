import MEGAL10n

extension ConfirmAccountViewController {
    @objc func showSubscriptionDialogIfNeeded() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails,
              accountDetails.type != .free else {
                  return
              }
        
        switch accountDetails.subscriptionMethodId {
        case .itunes:
            showSubscriptionDialog(
                message: Strings.Localizable.Account.Delete.Subscription.itunes,
                additionalOptionTitle: Strings.Localizable.Account.Delete.Subscription.Itunes.manage) {
                    if #available(iOS 15.0, *) {
                        UIApplication.showManageSubscriptions()
                    } else {
                        UIApplication.openAppleIDSubscriptionsPage()
                    }
                }

        case .googleWallet:
            showSubscriptionDialog(
                message: Strings.Localizable.Account.Delete.Subscription.googlePlay,
                additionalOptionTitle: Strings.Localizable.Account.Delete.Subscription.GooglePlay.visit) {
                    if let url = NSURL(string: "https://play.google.com/store/account/subscriptions") {
                        url.mnz_presentSafariViewController()
                    }
                }
            
        case .huaweiWallet:
            showSubscriptionDialog(
                message: Strings.Localizable.Account.Delete.Subscription.huaweiAppGallery,
                additionalOptionTitle: Strings.Localizable.Account.Delete.Subscription.HuaweiAppGallery.visit) {
                    if let url = NSURL(string: "https://consumer.huawei.com/en/mobileservices/") {
                        url.mnz_presentSafariViewController()
                    }
                }
            
        default:
            return
        }
    }

    private func showSubscriptionDialog(message: String,
                                        additionalOptionTitle: String? = nil,
                                        additionalOptionHander: (() -> Void)? = nil) {
        
        let alertController = UIAlertController(
            title: Strings.Localizable.Account.Delete.Subscription.title,
            message: message,
            preferredStyle: .alert)
        
        if let additionalOption = additionalOptionTitle {
            alertController.addAction(
                UIAlertAction(title: additionalOption,
                              style: .default) { _ in
                                  additionalOptionHander?()
                              }
            )
        }

        alertController.addAction(
            UIAlertAction(title: Strings.Localizable.ok,
                          style: .default,
                          handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
}
