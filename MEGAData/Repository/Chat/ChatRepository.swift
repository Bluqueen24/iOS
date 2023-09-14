import MEGADomain
import MEGASDKRepo

import Combine

public final class ChatRepository: ChatRepositoryProtocol {
    
    public static var newRepo: ChatRepository {
        ChatRepository(sdk: MEGASdk.shared, chatSDK: MEGAChatSdk.shared)
    }
    
    private let sdk: MEGASdk
    private let chatSDK: MEGAChatSdk
    
    private lazy var chatStatusUpdateListener: ChatStatusUpdateListener = { [unowned self] in
        let chatStatusUpdateListener = ChatStatusUpdateListener(sdk: chatSDK)
        chatStatusUpdateListener.addListener()
        removeChatStatusUpdateListener = chatStatusUpdateListener.removeListener
        return chatStatusUpdateListener
    }()
    
    private lazy var chatListItemUpdateListener: ChatListItemUpdateListener = { [unowned self] in
        let chatListItemUpdateListener = ChatListItemUpdateListener(sdk: chatSDK)
        chatListItemUpdateListener.addListener()
        removeChatListItemUpdateListener = chatListItemUpdateListener.removeListener
        return chatListItemUpdateListener
    }()
    
    private lazy var chatCallUpdateListener: ChatCallUpdateListener = { [unowned self] in
        let chatCallUpdateListener = ChatCallUpdateListener(sdk: chatSDK)
        chatCallUpdateListener.addListener()
        removeChatCallUpdateListener = chatCallUpdateListener.removeListener
        return chatCallUpdateListener
    }()
    
    private lazy var chatConnectionUpdateListener: ChatConnectionUpdateListener = { [unowned self] in
        let chatConnectionUpdateListener = ChatConnectionUpdateListener(sdk: chatSDK)
        chatConnectionUpdateListener.addListener()
        removeChatConnectionUpdateListener = chatConnectionUpdateListener.removeListener
        return chatConnectionUpdateListener
    }()

    private lazy var chatRequestListener: ChatRequestListener = { [unowned self] in
        let chatRequestListener = ChatRequestListener(sdk: chatSDK)
        chatRequestListener.addListener()
        removeChatRequestListener = chatRequestListener.removeListener
        return chatRequestListener
    }()

    private var removeChatStatusUpdateListener: (() -> Void)?
    private var removeChatListItemUpdateListener: (() -> Void)?
    private var removeChatCallUpdateListener: (() -> Void)?
    private var removeChatConnectionUpdateListener: (() -> Void)?
    private var removeChatRequestListener: (() -> Void)?

    public init(sdk: MEGASdk, chatSDK: MEGAChatSdk) {
        self.sdk = sdk
        self.chatSDK = chatSDK
    }
    
    deinit {
        removeChatStatusUpdateListener?()
        removeChatListItemUpdateListener?()
        removeChatCallUpdateListener?()
        removeChatStatusUpdateListener?()
        removeChatConnectionUpdateListener?()
        removeChatRequestListener?()
    }
    
    public func myUserHandle() -> HandleEntity {
        chatSDK.myUserHandle
    }
    
    public func chatStatus() -> ChatStatusEntity {
        chatSDK.onlineStatus().toChatStatusEntity()
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        chatSDK.setOnlineStatus(status.toMEGASChatStatus())
    }
    
    public func archivedChatListCount() -> UInt {
        chatSDK.archivedChatListItems?.size ?? 0
    }
    
    public func unreadChatMessagesCount() -> Int {
        chatSDK.unreadChats
    }
    
    public func chatConnectionStatus() -> ChatConnectionStatus {
        MEGAChatConnection(rawValue: chatSDK.initState().rawValue)?.toChatConnectionStatus() ?? .invalid
    }
    
    public func chatConnectionStatus(for chatId: ChatIdEntity) -> ChatConnectionStatus {
        chatSDK.chatConnectionState(chatId).toChatConnectionStatus()
    }
    
    public func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity? {
        chatSDK.chatListItem(forChatId: chatId)?.toChatListItemEntity()
    }
    
    public func retryPendingConnections() {
        sdk.retryPendingConnections()
        chatSDK.retryPendingConnections()
    }
    
    public func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        chatStatusUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never> {
        chatListItemUpdateListener
            .monitor
            .collect(.byTime(DispatchQueue.global(qos: .background), .seconds(5)))
            .eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        chatSDK.firstActiveCall != nil
    }
    
    public func activeCall() -> CallEntity? {
        chatSDK.firstActiveCall?.toCallEntity()
    }
    
    public func fetchMeetings() -> [ChatListItemEntity]? {
        guard let chatList = chatSDK.chatListItems(by: [.meetingOrNonMeeting, .archivedOrNonArchived], filter: .meeting) else { return nil }
        return (0..<chatList.size).map { chatList.chatListItem(at: $0).toChatListItemEntity() }
    }
    
    public func fetchNonMeetings() -> [ChatListItemEntity]? {
        guard let chatList = chatSDK.chatListItems(by: [.meetingOrNonMeeting, .archivedOrNonArchived], filter: []) else { return nil }
        return (0..<chatList.size).map { chatList.chatListItem(at: $0).toChatListItemEntity() }
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        guard let call = chatSDK.chatCall(forChatId: chatRoomId) else {
            return false
        }
        return call.isCallInProgress
    }
    
    public func isCallActive(for chatId: HandleEntity) -> Bool {
        guard let call = chatSDK.chatCall(forChatId: chatId) else {
            return false
        }
        return call.isActiveCall
    }
    
    public func myFullName() -> String? {
        chatSDK.myFullname
    }
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never> {
        chatCallUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> {
        chatConnectionUpdateListener
            .monitor
            .filter { $1 == chatId }
            .map(\.0)
            .eraseToAnyPublisher()
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        chatRequestListener
            .monitor
            .filter { $0.chatId == chatId && $1 == .setPrivateMode }
            .map(\.0)
            .eraseToAnyPublisher()
    }
    
    public func chatCall(for chatId: HandleEntity) -> CallEntity? {
        guard let call = chatSDK.chatCall(forChatId: chatId) else {
            return nil
        }
        
        return call.toCallEntity()
    }
}

private class ChatListener: NSObject, MEGAChatDelegate {
    private let sdk: MEGAChatSdk
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func addListener() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func removeListener() {
        sdk.remove(self)
    }
}

private final class ChatStatusUpdateListener: ChatListener {
    private let source = PassthroughSubject<(HandleEntity, ChatStatusEntity), Never>()
    var monitor: AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk!, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        guard !inProgress else {
            return
        }
        
        source.send((userHandle, onlineStatus.toChatStatusEntity()))
    }
}

private final class ChatListItemUpdateListener: ChatListener {
    private let source = PassthroughSubject<ChatListItemEntity, Never>()
    
    var monitor: AnyPublisher<ChatListItemEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    func onChatListItemUpdate(_ api: MEGAChatSdk!, item: MEGAChatListItem!) {
        source.send(item.toChatListItemEntity())
    }
}

private final class ChatConnectionUpdateListener: ChatListener {
    private let source = PassthroughSubject<(ChatConnectionStatus, ChatIdEntity), Never>()
    
    var monitor: AnyPublisher<(ChatConnectionStatus, ChatIdEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if let chatConnectionState = MEGAChatConnection(rawValue: Int(newState))?.toChatConnectionStatus() {
            source.send((chatConnectionState, chatId))
        }
    }
}

private final class ChatCallUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func addListener() {
        sdk.add(self)
    }
    
    func removeListener() {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.hasChanged(for: .status) {
            source.send(call.toCallEntity())
        }
    }
}

private final class ChatRequestListener: NSObject, MEGAChatRequestDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatRoomEntity, MEGAChatRequestType), Never>()
    
    var monitor: AnyPublisher<(ChatRoomEntity, MEGAChatRequestType), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func addListener() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func removeListener() {
        sdk.remove(self)
    }

    func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if let chatRoom = sdk.chatRoom(forChatId: request.chatHandle) {
            source.send((chatRoom.toChatRoomEntity(), request.type))
        }
    }
}
