import ChatRepo
import Combine
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

protocol MeetingContainerRouting: AnyObject, Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss(animated: Bool, completion: (() -> Void)?)
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
    func showEndMeetingOptions(presenter: UIViewController,
                               meetingContainerViewModel: MeetingContainerViewModel,
                               sender: UIButton)
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel)
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?)
    func renameChat()
    func showShareMeetingError()
    func enableSpeaker(_ enable: Bool)
    func displayParticipantInMainView(_ participant: CallParticipantEntity)
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    func didSwitchToGridView()
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)?)
    func removeEndCallDialog(finishCountDown: Bool, completion: (() -> Void)?)
    func showJoinMegaScreen()
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel)
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel)
    func showScreenShareWarning()
    func showMutedMessage(by name: String)
    func showProtocolErrorAlert()
}

final class MeetingContainerRouter: MeetingContainerRouting {
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private var isSpeakerEnabled: Bool
    private var selectWaitingRoomList: Bool
    private weak var baseViewController: UINavigationController?
    private weak var floatingPanelRouter: (any MeetingFloatingPanelRouting)?
    private var meetingParticipantsRouter: (any MeetingParticipantsLayoutRouting)?
    private weak var hangOrEndCallRouter: (any HangOrEndCallRouting)?
    private var appDidBecomeActiveSubscription: AnyCancellable?
    private weak var containerViewModel: MeetingContainerViewModel?
    private var endCallDialog: EndCallDialog?
    private lazy var chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
    
    private var createCallUseCase: CallUseCase<CallRepository> {
        let callRepository = CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)
        return CallUseCase(repository: callRepository)
    }
    
    static var isAlreadyPresented: Bool {
        MeetingContainerViewController.isAlreadyPresented
    }
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    
    init(presenter: UIViewController,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         isSpeakerEnabled: Bool,
         selectWaitingRoomList: Bool = false
    ) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
        self.isSpeakerEnabled = isSpeakerEnabled
        self.selectWaitingRoomList = selectWaitingRoomList
        
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Adding notifications for the call \(callId)")
        }
        
        subscribeToAppDidBecomeActiveSubscription(withChatRoom: chatRoom)
    }
    
    func build() -> UIViewController {
        let meetingNoUserJoinedUseCase = MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo)
        let analyticsEventUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: .shared))
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let viewModel = MeetingContainerViewModel(router: self,
                                                  chatRoom: chatRoom,
                                                  callUseCase: createCallUseCase,
                                                  chatRoomUseCase: chatRoomUseCase,
                                                  chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                                                  scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo),
                                                  callCoordinatorUseCase: CallCoordinatorUseCase(),
                                                  accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                                                  authUseCase: DIContainer.authUseCase,
                                                  noUserJoinedUseCase: meetingNoUserJoinedUseCase,
                                                  analyticsEventUseCase: analyticsEventUseCase,
                                                  megaHandleUseCase: megaHandleUseCase)
        let vc = MeetingContainerViewController(viewModel: viewModel)
        baseViewController = vc
        containerViewModel = viewModel
        return vc
    }
    
    func start() {
        guard Self.isAlreadyPresented == false else {
            MEGALogDebug("Meeting UI is already presented")
            return
        }
        
        let vc = build()
        vc.modalPresentationStyle = .fullScreen
        presenter?.present(vc, animated: false) {
            guard let vc = vc as? MeetingContainerViewController else { return }
            vc.configureUI()
        }
    }
    
    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showCallViewRouter(containerViewModel: containerViewModel)
        showFloatingPanel(containerViewModel: containerViewModel)
        isCallUIVisible = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        isCallUIVisible = false
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Meeting ended for call \(callId) - dismiss called will animated \(animated)")
        }
        
        dismissWaitingRoomAlertPresentedIfNeeded { [weak self] in
            guard let self else { return }
            guard let hangOrEndCallRouter else {
                dismissCallUI(animated: animated, completion: completion)
                return
            }
            hangOrEndCallRouter.dismiss(animated: true) {
                self.dismissCallUI(animated: animated, completion: completion)
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    func showShareMeetingError() {
        guard CustomModalAlertViewController.isAlreadyPresented == false else { return }
        
        let customModalAlertViewController = CustomModalAlertViewController()
        customModalAlertViewController.image = UIImage(resource: .chatLinkCreation)
        customModalAlertViewController.viewTitle = chatRoom.title
        customModalAlertViewController.firstButtonTitle = Strings.Localizable.close
        customModalAlertViewController.link = chatRoom.chatType == .meeting ? Strings.Localizable.Meetings.Sharelink.error : Strings.Localizable.noChatLinkAvailable
        customModalAlertViewController.firstCompletion = { [weak customModalAlertViewController] in
            customModalAlertViewController?.dismiss(animated: true, completion: nil)
        }
        customModalAlertViewController.overrideUserInterfaceStyle = .dark
        UIApplication.mnz_presentingViewController().present(customModalAlertViewController, animated: true)
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        if let floatingPanelRouter = floatingPanelRouter {
            floatingPanelRouter.dismiss()
            self.floatingPanelRouter = nil
        } else {
            showFloatingPanel(containerViewModel: containerViewModel)
        }
    }
    
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel) {
        guard floatingPanelRouter != nil else {
            selectWaitingRoomList = true
            showFloatingPanel(containerViewModel: containerViewModel)
            meetingParticipantsRouter?.showNavigation()
            return
        }
    }
    
    func showEndMeetingOptions(presenter: UIViewController,
                               meetingContainerViewModel: MeetingContainerViewModel,
                               sender: UIButton) {
        EndMeetingOptionsRouter(
            presenter: presenter,
            meetingContainerViewModel: meetingContainerViewModel,
            sender: sender
        ).start()
    }
    
    func showOptionsMenu(presenter: UIViewController,
                         sender: UIBarButtonItem,
                         isMyselfModerator: Bool,
                         containerViewModel: MeetingContainerViewModel) {
                
        let optionsMenuRouter = MeetingOptionsMenuRouter(presenter: presenter,
                                                         sender: sender,
                                                         isMyselfModerator: isMyselfModerator,
                                                         chatRoom: chatRoom,
                                                         containerViewModel: containerViewModel)
        optionsMenuRouter.start()
    }
    
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        guard UIActivityViewController.isAlreadyPresented == false else {
            MEGALogDebug("Meeting link Share controller is already presented.")
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: isGuestAccount ? nil : [SendToChatActivity(text: link)])
        if let barButtonSender = sender as? UIBarButtonItem {
            activityViewController.popoverPresentationController?.barButtonItem = barButtonSender
        } else if let buttonSender = sender as? UIButton {
            activityViewController.popoverPresentationController?.sourceView = buttonSender
            activityViewController.popoverPresentationController?.sourceRect = buttonSender.frame
        } else {
            MEGALogError("Parameter sender has a not allowed type")
            return
        }
        activityViewController.overrideUserInterfaceStyle = .dark
        activityViewController.completionWithItemsHandler = completion
        
        if let presenter = presenter {
            presenter.present(activityViewController, animated: true)
        } else {
            baseViewController?.present(activityViewController, animated: true)
        }
    }
    
    func renameChat() {
        meetingParticipantsRouter?.showRenameChatAlert()
    }
    
    func displayParticipantInMainView(_ participant: CallParticipantEntity) {
        meetingParticipantsRouter?.pinParticipantAsSpeaker(participant)
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {
        floatingPanelRouter?.didDisplayParticipantInMainView(participant)
    }
    
    func didSwitchToGridView() {
        floatingPanelRouter?.didSwitchToGridView()
    }
    
    func enableSpeaker(_ enable: Bool) {
        isSpeakerEnabled = enable
    }
    
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)? = nil) {
        guard self.endCallDialog == nil else { return }
        
        let endCallDialog = EndCallDialog(forceDarkMode: true) { [weak self] in
            self?.endCallDialog = nil
            self?.meetingParticipantsRouter?.endCallEndCountDownTimer()
            stayOnCallCompletion?()
        } endCallAction: { [weak self] in
            self?.endCallDialog = nil
            endCallCompletion()
        }

        meetingParticipantsRouter?.startCallEndCountDownTimer()
        endCallDialog.show()
        self.endCallDialog = endCallDialog
    }
    
    func removeEndCallDialog(finishCountDown: Bool = true, completion: (() -> Void)?) {
        guard endCallDialog != nil else {
            meetingParticipantsRouter?.endCallEndCountDownTimer()
            completion?()
            return
        }
        
        if finishCountDown {
            meetingParticipantsRouter?.endCallEndCountDownTimer()
        }
        endCallDialog?.dismiss(animated: true) { [weak self] in
            self?.endCallDialog = nil
            completion?()
        }
    }
    
    func showJoinMegaScreen() {
        EncourageGuestUserToJoinMegaRouter(presenter: UIApplication.mnz_presentingViewController()).start()
    }
    
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel) {
        let hangOrEndCallRouter = HangOrEndCallRouter(presenter: UIApplication.mnz_presentingViewController(), meetingContainerViewModel: containerViewModel)
        hangOrEndCallRouter.start()
        self.hangOrEndCallRouter = hangOrEndCallRouter
    }
    
    func showScreenShareWarning() {
        SVProgressHUD.configureHudDarkMode()
        SVProgressHUD.showError(withStatus: Strings.Localizable.Calls.ScreenShare.Waring.title)
    }
    
    func showMutedMessage(by name: String) {
        SVProgressHUD.configureHudDarkMode()
        SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Calls.ParticipantsInCall.mutedBy(name))
    }
    
    func showProtocolErrorAlert() {
        guard let presenter else { return }
        let alert = UIAlertController(
            title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.title,
            message: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.message,
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.Button.skip, style: .default)
        )
        let preferredAction = UIAlertAction(
            title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.Button.update, style: .default) { _ in
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id706857885") {
                    UIApplication.shared.open(url)
                }
            }
        alert.addAction(preferredAction)
        alert.preferredAction = preferredAction
        presenter.dismiss(animated: true) {
            presenter.present(alert, animated: true)
        }
    }
    
    // MARK: - Private methods.
    private func showCallViewRouter(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = MeetingParticipantsLayoutRouter(presenter: baseViewController,
                                            containerViewModel: containerViewModel,
                                            chatRoom: chatRoom,
                                            call: call)
        callViewRouter.start()
        self.meetingParticipantsRouter = callViewRouter
    }
    
    private func showFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        // When toggling the chatroom instance might be outdated. So fetching it again.
        guard let baseViewController = baseViewController,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
            return
        }
        let floatingPanelRouter = MeetingFloatingPanelRouter(
            presenter: baseViewController,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            isSpeakerEnabled: isSpeakerEnabled,
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            selectWaitingRoomList: selectWaitingRoomList
        )
        selectWaitingRoomList = false
        floatingPanelRouter.start()
        self.floatingPanelRouter = floatingPanelRouter
    }
    
    private func subscribeToAppDidBecomeActiveSubscription(withChatRoom chatRoom: ChatRoomEntity) {
        self.appDidBecomeActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                
                if self.createCallUseCase.call(for: chatRoom.chatId) == nil {
                    self.containerViewModel?.dispatch(.dismissCall(completion: nil))
                } else if let baseViewController = self.baseViewController,
                          !baseViewController.navigationBar.isHidden,
                          baseViewController.presentedViewController == nil,
                          let containerViewModel = self.containerViewModel {
                    self.showFloatingPanel(containerViewModel: containerViewModel)
                }
            }
    }
    
    private func dismissCallUI(animated: Bool, completion: (() -> Void)?) {
        floatingPanelRouter?.dismiss(animated: animated)
        baseViewController?.dismiss(animated: animated, completion: completion)
    }
    
    private func dismissWaitingRoomAlertPresentedIfNeeded(completion: @escaping () -> Void) {
        guard let presentedViewController = presenter?.presenterViewController()?.presentedViewController, presentedViewController.isKind(of: UIAlertController.self) else {
            completion()
            return
        }
        
        presentedViewController.dismiss(animated: false) {
            completion()
        }
    }
}
