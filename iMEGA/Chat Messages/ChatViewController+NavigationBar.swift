import Foundation
import MEGADomain

extension ChatViewController {
    private var rightBarButtons: [UIBarButtonItem] {
        var barButtons: [UIBarButtonItem] = []
        
        if chatRoom.isGroup {
            if chatRoom.ownPrivilege == .moderator {
                barButtons.append(addParticpantBarButtonItem)
            }
            
            barButtons.append(audioCallBarButtonItem)
        } else {
            barButtons = [videoCallBarButtonItem, audioCallBarButtonItem]
        }
        
        return barButtons
    }
    
    func configureNavigationBar() {
        addRightBarButtons()
        setTitleView()
    }
    
    func updateRightBarButtons() {
        guard !isEditing else {
            navigationItem.rightBarButtonItems = [cancelBarButtonItem]
            return
        }
        navigationItem.rightBarButtonItems = rightBarButtons
        
        let reachable = MEGAReachabilityManager.isReachable()
        let existsActiveCall = MEGAChatSdk.shared.mnz_existsActiveCall
        
        chatContentViewModel.dispatch(.updateCallNavigationBarButtons(shouldDisableAudioVideoCalling,
                                                                      isVoiceRecordingInProgress, reachable, existsActiveCall))
    }
    
    private func addRightBarButtons() {
        navigationItem.rightBarButtonItems = rightBarButtons
        updateRightBarButtons()
    }
    
    private func setTitleView() {
        let titleView = ChatTitleView.instanceFromNib
        titleView.chatRoom = chatRoom
        titleView.tapHandler = { [weak self] in
            self?.didTapTitle()
        }
        navigationItem.titleView = titleView
    }
    
    private func didTapTitle() {
        if chatRoom.isGroup {
            if MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
                return
            }
            pushGroupDetailsViewController()
        } else {
            pushContactDetailsViewController(withPeerHandle: chatRoom.peerHandle(at: 0))
        }
    }
    
    private func pushGroupDetailsViewController() {
        guard let navigationController else { return }
        if let scheduledMeeting = chatHasFutureScheduledMeeting() {
            MeetingInfoRouter(presenter: navigationController, scheduledMeeting: scheduledMeeting).start()
        } else {
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            if let groupDetailsViewController = storyboard.instantiateViewController(withIdentifier: "GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController {
                groupDetailsViewController.chatRoom = chatRoom
                navigationController.pushViewController(groupDetailsViewController, animated: true)
            } else {
                MEGALogError("ChatViewController: Could not GroupChatDetailsViewController")
            }
        }
    }
    
    private func chatHasFutureScheduledMeeting() -> ScheduledMeetingEntity? {
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared))
        let scheduledMeetings = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId)
        
        return scheduledMeetings.first(where: {
            if $0.rules.frequency == .invalid {
                return $0.endDate >= Date()
            } else {
                if let until = $0.rules.until {
                    return until >= Date()
                } else {
                    return true
                }
            }
        })
    }
    
    func pushContactDetailsViewController(withPeerHandle peerHandle: UInt64) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        
        guard let userEmail = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: peerHandle) else {
            return
        }
        
        contactDetailsVC.contactDetailsMode = chatRoom.isGroup ? .fromGroupChat : .fromChat
        contactDetailsVC.userEmail = userEmail
        contactDetailsVC.userHandle = peerHandle
        contactDetailsVC.groupChatRoom = chatRoom
        navigationController?.pushViewController(contactDetailsVC, animated: true)
    }
    
    @objc func addParticipant() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            present(viewController: participantsAddingViewFactory.noAvailableContactsAlert(inviteAction: showInviteContacts))
            return
        }
        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            present(viewController: participantsAddingViewFactory.allContactsAlreadyAddedAlert(inviteAction: showInviteContacts))
            return
        }
        
        let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .chatAddParticipant,
            additionallyExcludedParticipantsId: nil
        ) { [weak self] handles in
            guard let self = self else { return }
            for handle in handles {
                MEGAChatSdk.shared.invite(
                    toChat: self.chatRoom.chatId,
                    user: handle,
                    privilege: MEGAChatRoomPrivilege.standard.rawValue
                )
            }
        }
        
        guard let contactsNavigationController = contactsNavigationController else { return }
        present(viewController: contactsNavigationController)
    }
    
    private func showInviteContacts() {
        guard let inviteController = createParticipantsAddingViewFactory().inviteContactController() else { return }
        navigationController?.pushViewController(inviteController, animated: true)
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo),
            chatRoom: chatRoom.toChatRoomEntity()
        )
    }
}
