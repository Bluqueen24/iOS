import Foundation
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension GroupChatDetailsViewController {
    
    @objc func addChatCallDelegate() {
        MEGAChatSdk.shared.add(self as (any MEGAChatCallDelegate))
    }
    
    @objc func removeChatCallDelegate() {
        MEGAChatSdk.shared.remove(self as (any MEGAChatCallDelegate))
    }
    
    @objc func addChatRoomDelegate() {
        MEGAChatSdk.shared.addChatRoomDelegate(chatRoom.chatId, delegate: self)
    }
    
    @objc func removeChatRoomDelegate() {
        MEGAChatSdk.shared.removeChatRoomDelegate(chatRoom.chatId, delegate: self)
    }
    
    @objc func shouldShowAddParticipants() -> Bool {
        guard let chatRoom = chatRoom else { return false }
        let chatRoomPrivilege = chatRoom.ownPrivilege.toOwnPrivilegeEntity()
        return (chatRoom.ownPrivilege == .moderator || chatRoom.isOpenInviteEnabled) && !MEGASdk.isGuest && chatRoomPrivilege.isUserInChat
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: any MEGAChatRoomDelegate) {
        guard let chatRoom = ChatRoomRepository.sharedRepo.chatRoom(forChatId: chatId) else { return }
        
        if ChatRoomRepository.sharedRepo.isChatRoomOpen(chatRoom) {
            ChatRoomRepository.sharedRepo.closeChatRoom(chatId: chatRoom.chatId, delegate: delegate)
        }
        try? ChatRoomRepository.sharedRepo.openChatRoom(chatId: chatRoom.chatId, delegate: delegate)
    }
    
    @objc func showEndCallForAll() {
        let endCallDialog = EndCallDialog(
            type: .endCallForAll,
            forceDarkMode: false,
            autodismiss: true
        ) { [weak self] in
            self?.endCallDialog = nil
        } endCallAction: { [weak self] in
            guard let self = self,
                  let call = MEGAChatSdk.shared.chatCall(forChatId: self.chatRoom.chatId) else {
                return
            }
            
            let statsRepoSitory = AnalyticsRepository(sdk: MEGASdk.shared)
            AnalyticsEventUseCase(repository: statsRepoSitory).sendAnalyticsEvent(.meetings(.endCallForAll))
            
            MEGAChatSdk.shared.endChatCall(call.callId)
            self.navigationController?.popViewController(animated: true)
        }
        
        endCallDialog.show()
        self.endCallDialog = endCallDialog
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo),
            chatRoom: chatRoom.toChatRoomEntity()
        )
    }
    
    private func showInviteContacts() {
        guard let inviteController = createParticipantsAddingViewFactory().inviteContactController() else { return }
        navigationController?.pushViewController(inviteController, animated: true)
    }
    
    private func changeChatNotificationStatus(sender: UISwitch) {
        if sender.isOn {
            chatNotificationControl.turnOffDND(chatId: ChatIdEntity(chatRoom.chatId))
        } else {
            chatNotificationControl.turnOnDND(chatId: ChatIdEntity(chatRoom.chatId), isChatTypeMeeting: chatRoom.isMeeting, sender: sender)
        }
    }
    
    @objc func addParticipant() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            let noAvailableContactsAlert = participantsAddingViewFactory.noAvailableContactsAlert(inviteAction: showInviteContacts)
            present(noAvailableContactsAlert, animated: true)
            return
        }
        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            let allContactsAlreadyAddedAlert = participantsAddingViewFactory.allContactsAlreadyAddedAlert(inviteAction: showInviteContacts)
            present(allContactsAlreadyAddedAlert, animated: true)
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
        present(contactsNavigationController, animated: true)
    }
    
    @objc func configureAllowNonHostToAddParticipantsCell(_ cell: GroupChatDetailsViewTableViewCell) {
        cell.nameLabel.text = Strings.Localizable.Meetings.AddContacts.AllowNonHost.message
        cell.leftImageView.image = Asset.Images.Contacts.addContact.image
        cell.controlSwitch.isOn = chatRoom.isOpenInviteEnabled
        cell.delegate = self
    }
}

extension GroupChatDetailsViewController: MEGAChatCallDelegate {
    public func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard call.chatId == self.chatRoom.chatId else { return }
        
        let statusToReload: [MEGAChatCallStatus] = [.inProgress,
                                                    .userNoPresent,
                                                    .destroyed]
        if statusToReload.contains(call.status) {
            self.reloadData()
        }
    }
}

extension GroupChatDetailsViewController: MEGAChatRoomDelegate {
    public func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        if chat.hasChanged(for: .openInvite) {
            DispatchQueue.main.async {
                self.chatRoom = chat
                self.reloadData()
            }
        }
    }
}
 
extension GroupChatDetailsViewController: GroupChatDetailsViewTableViewCellDelegate {
    public func controlSwitchValueChanged(_ sender: UISwitch, from cell: GroupChatDetailsViewTableViewCell) {
        guard let section = tableView.indexPath(for: cell)?.section else { return }
        switch UInt(section) {
        case GroupChatDetailsSection.chatNotifications.rawValue:
            changeChatNotificationStatus(sender: sender)
        case GroupChatDetailsSection.allowNonHostToAddParticipants.rawValue:
            MEGAChatSdk.shared.openInvite(sender.isOn, chatId: chatRoom.chatId)
        default:
            break
        }
    }
}

extension GroupChatDetailsViewController: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        tableView?.reloadData()
    }
    
    func pushNotificationSettingsLoaded() {
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Int(GroupChatDetailsSection.chatNotifications.rawValue))) as? GroupChatDetailsViewTableViewCell else {
            return
        }
        if cell.controlSwitch != nil {
            cell.controlSwitch.isEnabled = true
        }
    }
}
