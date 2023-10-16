import Combine
import MEGADomain

final class ChatRoomParticipantsListViewModel: ObservableObject {
    
    private let initialParticipantsLoad: Int = 4
    
    private let router: any MeetingInfoRouting
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private var chatRoom: ChatRoomEntity
    private var invitedUserIdsToBypassWaitingRoom = Set<HandleEntity>()
    private var subscriptions = Set<AnyCancellable>()

    @Published var myUserParticipant: ChatRoomParticipantViewModel
    @Published var chatRoomParticipants = [ChatRoomParticipantViewModel]()
    @Published var shouldShowAddParticipants = false
    @Published var totalParticipantsCount = 0
    @Published var showExpandCollapseButton = true
    @Published var listExpanded = false

    init(
        router: some MeetingInfoRouting,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        chatRoom: ChatRoomEntity
    ) {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.callUseCase = callUseCase
        self.chatRoom = chatRoom
        
        myUserParticipant = ChatRoomParticipantViewModel(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            chatParticipantId: chatUseCase.myUserHandle(),
            chatRoom: chatRoom
        )
        
        updateShouldShowAddParticipants()
        updateParticipants()
        listenToInviteChanges()
        listenToParticipantsUpdate()
        listenToWaitingRoomUsersAllowUpdate()
    }
    
    func addParticipantTapped() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            router.showNoAvailableContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
                        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            router.showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
        
        router.inviteParticipants(
            withParticipantsAddingViewFactory: participantsAddingViewFactory,
            excludeParticipantsId: []
        ) { [weak self] userHandles in
            guard let self else { return }
            inviteParticipants(userHandles)
        }
    }
    
    func inviteParticipants(_ userHandles: [HandleEntity]) {
        if let call = callUseCase.call(for: chatRoom.chatId),
           shouldInvitedParticipantsBypassWaitingRoom() {
            userHandles.forEach {
                self.invitedUserIdsToBypassWaitingRoom.insert($0)
            }
            callUseCase.allowUsersJoinCall(call, users: userHandles)
        } else {
            userHandles.forEach { self.chatRoomUseCase.invite(toChat: self.chatRoom, userId: $0) }
        }
    }
    
    func seeMoreParticipantsTapped() {
        if listExpanded {
            loadInitialParticipants()
        } else {
            loadAllParticipants()
        }
        listExpanded.toggle()
    }
    
    // MARK: - Private methods
    
    private func loadAllParticipants() {
        chatRoomParticipants = chatRoom.peers
            .map {
                ChatRoomParticipantViewModel(
                    router: router,
                    chatRoomUseCase: chatRoomUseCase,
                    chatRoomUserUseCase: chatRoomUserUseCase,
                    chatUseCase: chatUseCase,
                    chatParticipantId: $0.handle,
                    chatRoom: chatRoom
                )
            }
    }
    
    private func loadInitialParticipants() {
        let peerCount = Int(chatRoom.peerCount)
        guard peerCount > 0 else {
            chatRoomParticipants = []
            return
        }
        let endIndex = (initialParticipantsLoad - 1) < peerCount ? (initialParticipantsLoad - 1) : peerCount
        chatRoomParticipants =  chatRoom.peers[0..<endIndex]
            .map {
                ChatRoomParticipantViewModel(
                    router: router,
                    chatRoomUseCase: chatRoomUseCase,
                    chatRoomUserUseCase: chatRoomUserUseCase,
                    chatUseCase: chatUseCase,
                    chatParticipantId: $0.handle,
                    chatRoom: chatRoom
                )
            }
    }
    
    private func shouldInvitedParticipantsBypassWaitingRoom() -> Bool {
        guard chatRoom.isWaitingRoomEnabled else { return false }
        let isModerator = chatRoom.ownPrivilege == .moderator
        let isOpenInviteEnabled = chatRoom.isOpenInviteEnabled
        return isModerator || isOpenInviteEnabled
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase,
            chatRoom: chatRoom
        )
    }
    
    private func updateShouldShowAddParticipants() {
        shouldShowAddParticipants = chatRoom.ownPrivilege == .moderator
        || (chatRoom.isOpenInviteEnabled && !accountUseCase.isGuest && chatRoom.ownPrivilege.isUserInChat)
    }
    
    private func listenToInviteChanges() {
        chatRoomUseCase.ownPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] _ in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId)else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateShouldShowAddParticipants()
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateShouldShowAddParticipants()
            })
            .store(in: &subscriptions)
    }
    
    private func listenToParticipantsUpdate() {
        chatRoomUseCase.participantsUpdated(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handles in
                guard  let self, handles.count != self.chatRoom.peers.count, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateParticipants()
            })
            .store(in: &subscriptions)
    }
    
    private func listenToWaitingRoomUsersAllowUpdate() {
        callUseCase
            .onCallUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self,
                      call.chatId == chatRoom.chatId,
                      call.changeType == .waitingRoomUsersAllow else {
                    return
                }
                allowWaitingRoomUsers(call.waitingRoomHandleList, for: call)
            }
            .store(in: &subscriptions)
    }
    
    private func allowWaitingRoomUsers(_ userHandles: [HandleEntity], for call: CallEntity) {
        for userId in userHandles where invitedUserIdsToBypassWaitingRoom.contains(userId) {
            chatRoomUseCase.invite(toChat: chatRoom, userId: userId)
            invitedUserIdsToBypassWaitingRoom.remove(userId)
        }
    }
    
    private func updateParticipants() {
        totalParticipantsCount = chatRoom.peers.count + 1
        showExpandCollapseButton = initialParticipantsLoad < totalParticipantsCount
        
        if showExpandCollapseButton {
            if listExpanded {
                loadAllParticipants()
            } else {
                loadInitialParticipants()
            }
        } else {
            loadAllParticipants()
        }
    }
}
