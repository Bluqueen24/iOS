import Foundation
import MEGADomain

public extension BackupEntity {
    init(id: Int = 0,
         name: String = "",
         deviceId: String = "",
         userAgent: String = "",
         rootHandle: HandleEntity = .invalid,
         lastHandleSync: HandleEntity = .invalid,
         type: BackupTypeEntity = .invalid,
         localFolder: String = "",
         extra: String = "",
         syncState: BackUpStateEntity = .unknown,
         substate: BackUpSubStateEntity = .noSyncError,
         status: BackupHeartbeatStatusEntity = .unknown,
         progress: UInt = 0,
         uploads: UInt = 0,
         downloads: UInt = 0,
         timestamp: Date? = nil,
         activityTimestamp: Date? = nil,
         isTesting: Bool = true) {
        self.init(
            id: id,
            name: name,
            deviceId: deviceId,
            userAgent: userAgent,
            rootHandle: rootHandle,
            lastHandleSync: lastHandleSync,
            type: type,
            localFolder: localFolder,
            extra: extra,
            syncState: syncState,
            substate: substate,
            status: status,
            progress: progress,
            uploads: uploads,
            downloads: downloads,
            timestamp: timestamp,
            activityTimestamp: activityTimestamp
        )
    }
}
