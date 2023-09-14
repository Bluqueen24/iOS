import Combine
import MEGADomain
import MEGAL10n

final class UserAvatarViewModel: ObservableObject {
    private let userId: MEGAHandle
    private let chatId: MEGAHandle
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var isRightToLeftLanguage: Bool?

    @Published private(set) var primaryAvatar: UIImage?
    
    private var subscriptions = Set<AnyCancellable>()
    private var updateAvatarTask: Task<Void, Never>?
    private var loadingChatRoomAvatarTask: Task<Void, Never>?
    private var loadingAvatarSubscription: AnyCancellable?
    
    init(userId: MEGAHandle,
         chatId: MEGAHandle,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
         userImageUseCase: some UserImageUseCaseProtocol,
         chatUseCase: any ChatUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol) {
        self.userId = userId
        self.chatId = chatId
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
    }

    // MARK: - Interface methods
    
    func loadData(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        loadingChatRoomAvatarTask = createLoadingChatRoomAvatarTask(isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    // MARK: - Private methods
    
    private func createLoadingChatRoomAvatarTask(isRightToLeftLanguage: Bool) -> Task<Void, Never> {
        Task { [weak self] in
            do {
                try await self?.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
            } catch {
                MEGALogDebug("Unable to fetch user avatar for \(userId) - \(error.localizedDescription)")
            }
        }
    }

    private func subscribeToAvatarUpdateNotification(forHandles handles: [HandleEntity]) {
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: handles)
            .sink { [weak self] _ in
                guard let self, let isRightToLeftLanguage = self.isRightToLeftLanguage else { return }
                
                self.updateAvatarTask = Task {
                    do {
                        try await self.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage, forceDownload: true)
                    } catch {
                        MEGALogDebug("Updating Avatar task failed for handles \(handles)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchAvatar(isRightToLeftLanguage: Bool, forceDownload: Bool = false) async throws {
        if let avatar = try await createAvatar(withHandle: userId, isRightToLeftLanguage: isRightToLeftLanguage) {
            await updatePrimaryAvatar(avatar)
        }
        
        subscribeToAvatarUpdateNotification(forHandles: [userId])
        try Task.checkCancellation()
        
        let downloadedAvatar = try await userAvatar(forHandle: userId, forceDownload: forceDownload)
        await updatePrimaryAvatar(downloadedAvatar)
    }
    
    private func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool) async throws -> UIImage? {
        let name = try await username(forUserHandle: handle, shouldUseMeText: false)
        
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle),
              let chatTitle = name   else {
            return nil
        }
        
        return try await userImageUseCase.createAvatar(withUserHandle: userId,
                                                       base64Handle: base64Handle,
                                                       avatarBackgroundHexColor: avatarBackgroundHexColor,
                                                       backgroundGradientHexColor: nil,
                                                       name: chatTitle,
                                                       isRightToLeftLanguage: isRightToLeftLanguage,
                                                       shouldCache: false,
                                                       useCache: false)
    }
    
    private func createAvatar(usingName name: String, isRightToLeftLanguage: Bool, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let initials = name
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap({ $0.count > 1 ? String($0.prefix(1)).uppercased() : nil })
            .joined(separator: "")
                
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: Colors.Chat.Avatar.background.color,
            backgroundGradientColor: UIColor.mnz_grayDBDBDB(),
            textColor: .white,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private func userAvatar(forHandle handle: HandleEntity, forceDownload: Bool = false) async throws -> UIImage {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.fetchAvatar(withUserHandle: handle, base64Handle: base64Handle, forceDownload: false)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return nil }
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoom)
            return usernames.first
        }
    }
    
    @MainActor
    private func updatePrimaryAvatar(_ avatar: UIImage) {
        primaryAvatar = avatar
    }
}
