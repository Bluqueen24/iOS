import Foundation

public struct CallEntity: Sendable {
    public enum CallStatusType: Sendable {
        case undefined
        case initial
        case userNoPresent
        case waitingRoom
        case connecting
        case joining
        case inProgress
        case terminatingUserParticipation
        case destroyed
    }
    
    public enum TermCodeType: Sendable {
        case invalid
        case userHangup
        case tooManyParticipants
        case reject
        case error
        case noParticipate
        case tooManyClients
        case protocolVersion
        case kicked
        case waitingRoomTimeout
    }
    
    public enum ChangeType: Sendable {
        case noChanges
        case status
        case localAVFlags
        case ringingStatus
        case callComposition
        case onHold
        case callSpeak
        case audioLevel
        case networkQuality
        case outgoingRingingStop
        case ownPermission
        case genericNotification
        case waitingRoomAllow
        case waitingRoomDeny
        case waitingRoomComposition
        case waitingRoomUsersEntered
        case waitingRoomUsersLeave
        case waitingRoomUsersAllow
        case waitingRoomUsersDeny
        case waitingRoomPushedFromCall
    }
    
    public enum ConfigurationType: Sendable {
        case audio
        case video
        case anyFlag
    }
    
    public enum CompositionChangeType: Sendable {
        case peerRemoved
        case noChange
        case peerAdded
    }
    
    public enum NotificationType: Sendable {
        case invalid
        case serverError
        case sfuDeny
    }
    
    public let status: CallStatusType?
    public let chatId: HandleEntity
    public let callId: HandleEntity
    public let changeType: ChangeType?
    public let duration: Int64
    public let initialTimestamp: Int64
    public let finalTimestamp: Int64
    public let hasLocalAudio: Bool
    public let hasLocalVideo: Bool
    public let termCodeType: TermCodeType?
    public let isRinging: Bool
    public let callCompositionChange: CompositionChangeType?
    public let numberOfParticipants: Int
    public let isOnHold: Bool
    public let sessionClientIds: [HandleEntity]
    public let clientSessions: [ChatSessionEntity]
    public let participants: [HandleEntity]
    public let waitingRoomStatus: WaitingRoomStatus
    public let waitingRoom: WaitingRoomEntity?
    public let waitingRoomHandleList: [HandleEntity]
    public let uuid: UUID
    
    public init(status: CallStatusType?, chatId: HandleEntity, callId: HandleEntity, changeType: ChangeType?, duration: Int64, initialTimestamp: Int64, finalTimestamp: Int64, hasLocalAudio: Bool, hasLocalVideo: Bool, termCodeType: TermCodeType?, isRinging: Bool, callCompositionChange: CompositionChangeType?, numberOfParticipants: Int, isOnHold: Bool, sessionClientIds: [HandleEntity], clientSessions: [ChatSessionEntity], participants: [HandleEntity], waitingRoomStatus: WaitingRoomStatus, waitingRoom: WaitingRoomEntity?, waitingRoomHandleList: [HandleEntity], uuid: UUID) {
        self.status = status
        self.chatId = chatId
        self.callId = callId
        self.changeType = changeType
        self.duration = duration
        self.initialTimestamp = initialTimestamp
        self.finalTimestamp = finalTimestamp
        self.hasLocalAudio = hasLocalAudio
        self.hasLocalVideo = hasLocalVideo
        self.termCodeType = termCodeType
        self.isRinging = isRinging
        self.callCompositionChange = callCompositionChange
        self.numberOfParticipants = numberOfParticipants
        self.isOnHold = isOnHold
        self.sessionClientIds = sessionClientIds
        self.clientSessions = clientSessions
        self.participants = participants
        self.waitingRoomStatus = waitingRoomStatus
        self.waitingRoom = waitingRoom
        self.waitingRoomHandleList = waitingRoomHandleList
        self.uuid = uuid
    }
}

extension CallEntity: Hashable {
    public static func == (lhs: CallEntity, rhs: CallEntity) -> Bool {
        lhs.callId == rhs.callId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(callId)
    }
}

extension CallEntity: Identifiable {
    public var id: HandleEntity { callId }
}
