import MEGADomain

// MARK: - Use case protocol -
protocol MeetingCreatingUseCaseProtocol {
    func startCall(_ startCall: StartCallEntity, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createChatLink(forChatId chatId: UInt64)
}

// MARK: - Use case implementation -
struct MeetingCreatingUseCase<T: MeetingCreatingRepositoryProtocol>: MeetingCreatingUseCaseProtocol {

    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
    
    func startCall(_ startCall: StartCallEntity, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        repository.startCall(startCall, completion: completion)
    }
    
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        repository.joinChatCall(forChatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, userHandle: userHandle, completion: completion)
    }
    
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        repository.joinChatWithoutAnswerCall(forChatId: chatId, userHandle: userHandle, completion: completion)
    }
    
    func getUsername() -> String {
        repository.getUsername()
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        repository.getCall(forChatId: chatId)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        repository.createChatLink(forChatId: chatId)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        repository.checkChatLink(link: link, completion: completion)
    }

    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        repository.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link, completion: completion, karereInitCompletion: karereInitCompletion)
    }
    
}
