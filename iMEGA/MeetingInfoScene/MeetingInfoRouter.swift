import ChatRepo
import Combine
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo

final class MeetingInfoRouter: NSObject, MeetingInfoRouting {
    private(set) var presenter: UINavigationController
    private let scheduledMeeting: ScheduledMeetingEntity
    private var link: String?
    private var inviteToMegaNavigationController: MEGANavigationController?

    init(presenter: UINavigationController,
         scheduledMeeting: ScheduledMeetingEntity) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: .shareInstance())
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdk.shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let viewModel = MeetingInfoViewModel(
            scheduledMeeting: scheduledMeeting,
            router: self,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: ChatUseCase(
                chatRepo: ChatRepository(
                    sdk: MEGASdk.shared,
                    chatSDK: MEGAChatSdk.shared)
            ),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        )
        let viewController = MeetingInfoViewController(viewModel: viewModel)
        
        return viewController
    }
    
    func start() {
        presenter.pushViewController(build(), animated: true)
    }
    
    func showSharedFiles(for chatRoom: ChatRoomEntity) {
        guard let MEGAChatRoom = chatRoom.toMEGAChatRoom() else {
            return
        }
        presenter.pushViewController(ChatSharedItemsViewController.instantiate(with: MEGAChatRoom), animated: true)
    }

    func showManageChatHistory(for chatRoom: ChatRoomEntity) {
        ManageChatHistoryViewRouter(chatId: chatRoom.chatId, isChatTypeMeeting: true, navigationController: presenter).start()
    }
    
    func showEnableKeyRotation(for chatRoom: ChatRoomEntity) {
        CustomModalAlertRouter(.enableKeyRotation, presenter: presenter, chatId: chatRoom.chatId).start()
    }
    
    func closeMeetingInfoView() {
        presenter.popViewController(animated: true)
    }
    
    func showLeaveChatAlert(leaveAction: @escaping(() -> Void)) {
        let alertController = UIAlertController(title: Strings.Localizable.youWillNoLongerHaveAccessToThisConversation, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.leave, style: .default) { _ in
            leaveAction()
        })
        presenter.present(alertController, animated: true)
    }
    
    func showShareActivity(_ link: String, title: String?, description: String?) {
        guard let url = URL(string: link), let sourceView = presenter.viewControllers.first?.view else { return }
        let metadataItemSource = ContactLinkPresentationItemSource(title: title ?? "", description: description ?? "", icon: Asset.Images.Logo.megaShareContactLink, url: url)
        let shareActivity = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [SendToChatActivity(text: link)])
        shareActivity.popoverPresentationController?.sourceView = sourceView
        presenter.present(shareActivity, animated: true)
    }

    func showSendToChat(_ link: String) {
        self.link = link
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.sendToChatActivityDelegate = self
        sendToViewController.sendMode = .text
        
        presenter.present(navigationController, animated: true)
    }

    func showLinkCopied() {
        SVProgressHUD.show(Asset.Images.Hud.hudSuccess.image, status: Strings.Localizable.Meetings.Info.ShareOptions.ShareLink.linkCopied)
    }
    
    func showParticipantDetails(email: String, userHandle: HandleEntity, chatRoom: ChatRoomEntity) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        contactDetailsVC.contactDetailsMode = .fromGroupChat
        contactDetailsVC.userEmail = email
        contactDetailsVC.userHandle = userHandle
        contactDetailsVC.groupChatRoom = chatRoom.toMEGAChatRoom()
        
        presenter.pushViewController(contactDetailsVC, animated: true)
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticpantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        guard let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .inviteParticipants,
            additionallyExcludedParticipantsId: excludeParticpantsId,
            selectedUsersHandler: selectedUsersHandler
        ) else { return }
        
        presenter.present(contactsNavigationController, animated: true)
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.allContactsAlreadyAddedAlert)
        
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.noAvailableContactsAlert)
    }
    
    func edit(meeting: ScheduledMeetingEntity) -> AnyPublisher<ScheduledMeetingEntity, Never> {
        let viewConfiguration = ScheduleMeetingUpdateViewConfiguration(
            scheduledMeeting: meeting,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        
        let router = ScheduleMeetingRouter(presenter: presenter, viewConfiguration: viewConfiguration)
        router.start()
        return router.onMeetingUpdate()
    }
    
    // MARK: - Private methods.
    
    private func showInviteToMega(_ inviteContactsViewController: InviteContactViewController) {
        let navigationController = MEGANavigationController(rootViewController: inviteContactsViewController)
        
        let backBarButton = UIBarButtonItem(
            image: Asset.Images.Chat.backArrow.image,
            style: .plain,
            target: self,
            action: #selector(self.dismissInviteContactsScreen)
        )
        
        navigationController.addLeftDismissBarButton(backBarButton)
        navigationController.overrideUserInterfaceStyle = .dark
        self.inviteToMegaNavigationController = navigationController
        presenter.present(navigationController, animated: true)
    }
    
    private func showContactsAlert(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        action: (@escaping () -> Void) -> UIAlertController
    ) {
        let contactsAlert = action {
            guard let inviteContactController = participantsAddingViewFactory.inviteContactController() else { return }
            self.showInviteToMega(inviteContactController)
        }
        
        contactsAlert.overrideUserInterfaceStyle = .dark
        presenter.present(contactsAlert, animated: true)
    }
    
    @objc private func dismissInviteContactsScreen() {
        self.inviteToMegaNavigationController?.dismiss(animated: true)
        self.inviteToMegaNavigationController = nil
    }
}

extension MeetingInfoRouter: SendToChatActivityDelegate {
    func send(_ viewController: SendToViewController!, didFinishActivity completed: Bool) {
        viewController.dismiss(animated: true)
    }
    
    func textToSend() -> String {
        link ?? ""
    }
}
