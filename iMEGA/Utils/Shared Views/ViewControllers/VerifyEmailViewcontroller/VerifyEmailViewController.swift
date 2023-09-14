import MEGAL10n
import MEGASDKRepo
import UIKit

class VerifyEmailViewController: UIViewController {

    @IBOutlet weak var warningGradientView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!

    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!

    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    // MARK: Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfBlocked), name:
            UIApplication.willEnterForegroundNotification, object: nil)
        configureUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            localizeLabels()
            boldenText()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradientBackground()
    }

    // MARK: Private

    func configureUI() {
        localizeLabels()
        boldenText()
        updateAppearance()
    }
    
    func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        resendButton.mnz_setupBasic(traitCollection)

        topSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        hintButton.setTitleColor(.mnz_turquoise(for: traitCollection), for: .normal)
        hintButton.backgroundColor = .mnz_tertiaryBackgroundElevated(traitCollection)
        bottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        hintLabel.textColor = UIColor .mnz_subtitles(for: traitCollection)
    }

    func addGradientBackground () {
        let gradient = CAGradientLayer()
        gradient.frame = warningGradientView.bounds
        gradient.colors = [Colors.SharedViews.VerifyEmail.firstGradient.color.cgColor,
                           Colors.SharedViews.VerifyEmail.secondGradient.color.cgColor]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)

        warningGradientView.layer.addSublayer(gradient)
    }

    func boldenText() {
        guard let bottomString = bottomDescriptionLabel.text?.replacingOccurrences(of: "[S]", with: "") else { return }

        let bottomStringComponents = bottomString.components(separatedBy: "[/S]")
        guard let textToBolden = bottomStringComponents.first, let textRegular = bottomStringComponents.last else { return }

        let attributtedString = NSMutableAttributedString(string: textToBolden, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(style: .callout, weight: .semibold)])
        let regularlString = NSAttributedString(string: textRegular, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .callout)])
        attributtedString.append(regularlString)

        bottomDescriptionLabel.attributedText = attributtedString
    }

    func showWhyIAmBlocked() {
        let customModal = CustomModalAlertViewController.init()

        customModal.image = Asset.Images.VerifyEmail.lockedAccounts.image
        customModal.viewTitle = Strings.Localizable.lockedAccounts
        customModal.detail = Strings.Localizable.itIsPossibleThatYouAreUsingTheSamePasswordForYourMEGAAccountAsForOtherServicesAndThatAtLeastOneOfTheseOtherServicesHasSufferedADataBreach + "\n\n" + Strings.Localizable.yourPasswordLeakedAndIsNowBeingUsedByBadActorsToLogIntoYourAccountsIncludingButNotLimitedToYourMEGAAccount
        customModal.dismissButtonTitle = Strings.Localizable.close

        present(customModal, animated: true, completion: nil)
    }

    func localizeLabels() {
        topDescriptionLabel.text = Strings.Localizable.yourAccountHasBeenTemporarilySuspendedForYourSafety
        bottomDescriptionLabel.text = Strings.Localizable.sPleaseVerifyYourEmailSAndFollowItsStepsToUnlockYourAccount
        resendButton.setTitle(Strings.Localizable.resend, for: .normal)
        logoutButton.setTitle(Strings.Localizable.logoutLabel, for: .normal)
        hintButton.setTitle(Strings.Localizable.whyAmISeeingThis, for: .normal)
        hintLabel.text = Strings.Localizable.emailSent
    }

    @objc func checkIfBlocked() {
        let whyAmIBlockedRequestDelegate = RequestDelegate { result in
            guard case let .success(request) = result, request.number == 0 else {
                return
            }
            
            if MEGASdk.shared.rootNode == nil {
                guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else { return }
                let loginRequestDelegate = MEGALoginRequestDelegate.init()
                MEGASdk.shared.fastLogin(withSession: session, delegate: loginRequestDelegate)
            }
            
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.dismiss(animated: true, completion: nil)
        }
        MEGASdk.shared.whyAmIBlocked(with: whyAmIBlockedRequestDelegate)
    }

    // MARK: Actions

    @IBAction func tapHintButton(_ sender: Any) {
        showWhyIAmBlocked()
    }

    @IBAction func tapResendButton(_ sender: Any) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            SVProgressHUD.show()
            let resendVerificationEmailDelegate = RequestDelegate(successCodes: [.apiOk, .apiEArgs]) { result in
                SVProgressHUD.dismiss()
                if case .success = result {
                    self.hintLabel.isHidden = false
                } else {
                    SVProgressHUD.showError(withStatus: Strings.Localizable.EmailAlreadySent.pleaseWaitAFewMinutesBeforeTryingAgain)
                }
            }
            MEGASdk.shared.resendVerificationEmail(with: resendVerificationEmailDelegate)
        }
    }

    @IBAction func tapLogoutButton(_ sender: Any) {
        MEGASdk.shared.logout()
    }
}
