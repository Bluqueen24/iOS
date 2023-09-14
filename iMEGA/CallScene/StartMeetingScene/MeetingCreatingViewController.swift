import MEGADomain
import MEGAL10n
import MEGAUIKit
import UIKit

class MeetingCreatingViewController: UIViewController, UITextFieldDelegate {
    
    private struct AvatarProperties {
        static let initials = "G"
        static let font = UIFont.preferredFont(forTextStyle: .title1).withWeight(.semibold)
        static let textColor = UIColor.white
        static let size = CGSize(width: 80, height: 80)
        static let backgroundColor = Colors.CallScene.avatarBackground.color
        static let backgroundGradientColor = Colors.CallScene.avatarBackgroundGradient.color
    }
    
    private struct Constants {
        static let bottomBarText = UIFont.preferredFont(style: .title3, weight: .semibold)
        static let bottomBarButtonText = UIFont.preferredFont(forTextStyle: .headline)
        static let backgroundColor = #colorLiteral(red: 0.2, green: 0.1843137255, blue: 0.1843137255, alpha: 1)
        static let textColor = UIColor.white
        static let iconTintColorNormal = UIColor.white
        static let iconTintColorSelected = UIColor.black
        static let iconBackgroundColorNormal = #colorLiteral(red: 0.1333158016, green: 0.1333456039, blue: 0.1333118975, alpha: 1)
        static let iconBackgroundColorSelected = UIColor.white
        static let meetingNameTextColor = UIColor.white.withAlphaComponent(0.2)
        static let placeholderTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
    
    @IBOutlet weak var localUserView: LocalUserView!
    @IBOutlet weak var enableDisableVideoButton: UIButton!
    @IBOutlet weak var muteUnmuteMicrophoneButton: UIButton!
    @IBOutlet weak var speakerQuickActionView: MeetingSpeakerQuickActionView!
    @IBOutlet weak var firstNameTextfield: UITextField!
    @IBOutlet weak var lastNameTextfield: UITextField!
    @IBOutlet weak var meetingNameInputTextfield: UITextField!
    @IBOutlet weak var startMeetingButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // MARK: - Internal properties
    let viewModel: MeetingCreatingViewModel
    var configurationType: MeetingConfigurationType?

     init(viewModel: MeetingCreatingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForNotifications()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.close,
            style: .plain,
            target: self,
            action: #selector(dissmissVC(_:))
        )

        configureUI()
                
        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }

        viewModel.dispatch(.onViewReady)
    }
    
    // MARK: - Private methods.
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func textFieldTextChanged(textField: UITextField) {
        guard let text = textField.text else { return }
        
        switch textField {
        case firstNameTextfield:
            viewModel.dispatch(.updateFirstName(text))
            updateJoinMeetingButton()
            
        case lastNameTextfield:
            viewModel.dispatch(.updateLastName(text))
            updateJoinMeetingButton()

        case meetingNameInputTextfield:
            viewModel.dispatch(.updateMeetingName(text))
            
        default:
            break
        }
    }
    
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        
        firstNameTextfield.font = Constants.bottomBarText
        firstNameTextfield.delegate = self
        firstNameTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        lastNameTextfield.font = Constants.bottomBarText
        lastNameTextfield.delegate = self
        lastNameTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        meetingNameInputTextfield.font = Constants.bottomBarText
        meetingNameInputTextfield.delegate = self
        meetingNameInputTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        startMeetingButton.setTitle(Strings.Localizable.Meetings.CreateMeeting.startMeeting, for: .normal)
        startMeetingButton.mnz_setupPrimary(traitCollection)
        startMeetingButton.titleLabel?.font = Constants.bottomBarButtonText
        
        speakerQuickActionView.properties = MeetingQuickActionView.Properties(
            iconTintColor: MeetingQuickActionView.Properties.StateColor(normal: Constants.iconTintColorNormal, selected: Constants.iconTintColorSelected),
            backgroundColor: MeetingQuickActionView.Properties.StateColor(normal: Constants.iconBackgroundColorNormal, selected: Constants.iconBackgroundColorSelected)
        )
    }
        
    @objc private func dissmissVC(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.didTapCloseButton)
    }
    
    private func excuteCommand(_ command: MeetingCreatingViewModel.Command) {
        switch command {
        case .configView(let title, let type, let isMicrophoneEnabled):
            self.title = title
            configurationType = type
            localUserView.configureForFullSize()
            meetingNameInputTextfield.isEnabled = type == .start
            muteUnmuteMicrophoneButton.isSelected = !isMicrophoneEnabled
            configureMeetingFor(type: type, title: title)
        case .updateMeetingName(let name):
            title = name.isEmpty ? meetingNameInputTextfield.placeholder : name
            if meetingNameInputTextfield.text != name {
                meetingNameInputTextfield.text = name
            }
        case .updateAvatarImage(let image):
            localUserView.updateAvatar(image: image)
        case .updateVideoButton(enabled: let isSelected):
            enableDisableVideoButton.isSelected = isSelected
            localUserView.switchVideo(to: isSelected)
        case .updateMicrophoneButton(enabled: let isSelected):
            muteUnmuteMicrophoneButton.isSelected = !isSelected
        case .loadingStartMeeting:
            showLoadingStartMeeting()
        case .loadingEndMeeting:
            showLoadingEndMeeting()
        case .localVideoFrame(width: let width, height: let height, buffer: let buffer):
            guestVideoFrame(width: width, height: height, buffer: buffer)
        case .updatedAudioPortSelection(let audioPort, let bluetoothAudioRouteAvailable):
            selectedAudioPortUpdated(audioPort, isBluetoothRouteAvailable: bluetoothAudioRouteAvailable)
        case .updateCameraPosition:
            break
        }
    }
    
    private func forceDarkNavigationUI() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
    
    private func selectedAudioPortUpdated(_ selectedAudioPort: AudioPort, isBluetoothRouteAvailable: Bool) {
        if isBluetoothRouteAvailable {
            speakerQuickActionView.addRoutingView()
        } else {
            speakerQuickActionView.removeRoutingView()
        }
        speakerQuickActionView.selectedAudioPortUpdated(selectedAudioPort, isBluetoothRouteAvailable: isBluetoothRouteAvailable)
    }
    
    private func guestVideoFrame(width: Int, height: Int, buffer: Data!) {
        localUserView.frameData(width: width, height: height, buffer: buffer)
    }
    
    private func updateJoinMeetingButton() {
        guard let configType = configurationType,
              configType == .guestJoin,
              let firstName = firstNameTextfield.text,
              let lastname = lastNameTextfield.text else {
            return
        }
        
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastname.trimmingCharacters(in: .whitespaces)
        startMeetingButton.isEnabled = !trimmedFirstName.isEmpty && !trimmedLastName.isEmpty
        startMeetingButton.alpha = startMeetingButton.isEnabled ? 1.0 : 0.5
    }
    
    private func showLoadingEndMeeting() {
        startMeetingButton.isHidden = false
        loadingIndicator.stopAnimating()
        
        firstNameTextfield.isEnabled = true
        lastNameTextfield.isEnabled = true
        meetingNameInputTextfield.isEnabled = true
        
        enableDisableVideoButton.isUserInteractionEnabled = true
        speakerQuickActionView.isUserInteractionEnabled = true
        muteUnmuteMicrophoneButton.isUserInteractionEnabled = true
    }
    
    fileprivate func showLoadingStartMeeting() {
        startMeetingButton.isHidden = true
        loadingIndicator.startAnimating()
        
        firstNameTextfield.isEnabled = false
        lastNameTextfield.isEnabled = false
        meetingNameInputTextfield.isEnabled = false
        
        enableDisableVideoButton.isUserInteractionEnabled = false
        speakerQuickActionView.isUserInteractionEnabled = false
        muteUnmuteMicrophoneButton.isUserInteractionEnabled = false
        
        resignFirstResponder()
    }
    
    private func configureMeetingFor(type: MeetingConfigurationType, title: String) {
        switch type {
        case .guestJoin:
            meetingNameInputTextfield.isHidden = true
            startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.Guest.joinButtonText, for: .normal)
            startMeetingButton.isEnabled = false
            startMeetingButton.alpha = 0.5
            
            firstNameTextfield.attributedPlaceholder = NSAttributedString(
                string: Strings.Localizable.firstName,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                             NSAttributedString.Key.font: Constants.bottomBarText]
            )
            lastNameTextfield.attributedPlaceholder = NSAttributedString(
                string: Strings.Localizable.lastName,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                             NSAttributedString.Key.font: Constants.bottomBarText]
            )
            firstNameTextfield.isHidden = false
            lastNameTextfield.isHidden = false
            
            guard let avatarImage = UIImage(forName: AvatarProperties.initials, size: AvatarProperties.size, backgroundColor: AvatarProperties.backgroundColor, backgroundGradientColor: AvatarProperties.backgroundGradientColor, textColor: AvatarProperties.textColor, font: AvatarProperties.font) else { return }
            localUserView.updateAvatar(image: avatarImage)
        case .join:
            meetingNameInputTextfield.isHidden = true
            startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.LoggedInUser.joinButtonText, for: .normal)
            
            firstNameTextfield.isHidden = true
            lastNameTextfield.isHidden = true
            
            viewModel.dispatch(.loadAvatarImage)
            
        case .start:
            meetingNameInputTextfield.attributedPlaceholder = NSAttributedString(
                string: title,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.meetingNameTextColor]
            )
            firstNameTextfield.isHidden = true
            lastNameTextfield.isHidden = true
            meetingNameInputTextfield.isHidden = false
            viewModel.dispatch(.loadAvatarImage)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextfield {
            lastNameTextfield.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    @IBAction func videoButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapVideoButton)
    }
    
    @IBAction func micButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapMicroPhoneButton)
    }
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapSpeakerButton)
    }
    
    @IBAction func startMeetingButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapStartMeetingButton)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval, let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        bottomConstraint.constant = keyboardValue.cgRectValue.height - view.safeAreaInsets.bottom
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

        bottomConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}

extension MeetingCreatingViewController: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        forceDarkNavigationUI()
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
}
