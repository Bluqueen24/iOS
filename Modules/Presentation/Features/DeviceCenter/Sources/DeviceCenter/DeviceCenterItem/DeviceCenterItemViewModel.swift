import Combine
import MEGADomain
import MEGAL10n
import MEGAUI
import SwiftUI

public class DeviceCenterItemViewModel: ObservableObject, Identifiable {    
    private let router: (any DeviceListRouting)?
    private let refreshDevicesPublisher: PassthroughSubject<Void, Never>?
    private let deviceCenterUseCase: DeviceCenterUseCaseProtocol
    private let nodeUseCase: (any NodeUseCaseProtocol)?
    private let deviceCenterBridge: DeviceCenterBridge
    private var itemType: DeviceCenterItemType
    var assets: ItemAssets
    var availableActions: [DeviceCenterAction]
    var statusSubtitle: String?
    var isBackup: Bool = false
    var hasErrorStatus: Bool = false
    
    @Published var name: String = ""
    @Published var iconName: String?
    @Published var statusIconName: String?
    @Published var statusTitle: String = ""
    @Published var statusColorName: String = ""
    @Published var shouldShowBackupPercentage: Bool = false
    @Published var backupPercentage: String = ""
    
    init(router: (any DeviceListRouting)? = nil,
         refreshDevicesPublisher: PassthroughSubject<Void, Never>? = nil,
         deviceCenterUseCase: DeviceCenterUseCaseProtocol,
         nodeUseCase: (any NodeUseCaseProtocol)? = nil,
         deviceCenterBridge: DeviceCenterBridge,
         itemType: DeviceCenterItemType,
         assets: ItemAssets,
         availableActions: [DeviceCenterAction]) {
        self.router = router
        self.refreshDevicesPublisher = refreshDevicesPublisher
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.deviceCenterBridge = deviceCenterBridge
        self.itemType = itemType
        self.assets = assets
        self.availableActions = availableActions
        
        self.configure()
    }
    
    func configure() {
        switch itemType {
        case .backup(let backup):
            name = backup.name
            statusSubtitle = backupStatusDetailedErrorMessage()
            hasErrorStatus = statusSubtitle != nil
            isBackup = true
            
        case .device(let device):
            name = device.name.isNotEmpty ? device.name : assets.defaultName ?? ""
        }
        
        iconName = assets.iconName
        statusTitle = assets.backupStatus.title
        statusIconName = assets.backupStatus.iconName
        statusColorName = assets.backupStatus.colorName
        
        calculateProgress()
    }
    
    private func calculateProgress() {
        if assets.backupStatus.status == .updating {
            var progress = 0
            switch itemType {
            case .backup(let backup):
                progress = Int(backup.progress)
                
            case .device(let device):
                progress = device.backups?.first(where: {
                    $0.backupStatus == .updating
                }).flatMap {
                    Int($0.progress)
                } ?? 0
            }
            progress = min(progress, 100)
            
            backupPercentage = "\(progress) %"
            shouldShowBackupPercentage = progress > 0
        }
    }
    
    private func nodeForEntityType() -> NodeEntity? {
        guard case .backup(let backupEntity) = itemType else { return nil }
        return nodeUseCase?.nodeForHandle(backupEntity.rootHandle)
    }
    
    func showDetail() {
        guard let router else { return }
        if case let .device(device) = itemType {
            let currentDeviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            if device.id == currentDeviceUUID && device.status == .noCameraUploads {
                router.showCurrentDeviceEmptyState(currentDeviceUUID, deviceName: UIDevice.current.modelName)
            } else {
                let currentDeviceId = deviceCenterUseCase.loadCurrentDeviceId()
                router.showDeviceBackups(
                    device,
                    isCurrentDevice: device.id == currentDeviceUUID || (device.id == currentDeviceId)
                )
            }
        }
    }
    
    @MainActor
    func executeAction(_ type: DeviceCenterActionType) async {
        switch itemType {
        case .backup:
            switch type {
            case .cameraUploads:
                deviceCenterBridge.cameraUploadActionTapped { [weak self] in
                    self?.refreshDevicesPublisher?.send()
                }
            case .info:
                guard let node = nodeForEntityType() else { return }
                deviceCenterBridge.infoActionTapped(node)
            case .showInCloudDrive:
                guard let nodeEntity = nodeForEntityType() else { return }
                
                deviceCenterBridge.showInCloudDriveActionTapped(nodeEntity)
            case .showInBackups:
                guard let nodeEntity = nodeForEntityType() else { return }
                
                deviceCenterBridge.showInBackupsActionTapped(nodeEntity)
            default: break
            }
        case .device(let device):
            switch type {
            case .cameraUploads:
                deviceCenterBridge.cameraUploadActionTapped { [weak self] in
                    self?.refreshDevicesPublisher?.send()
                }
            case .rename:
                let deviceNames = await deviceCenterUseCase.fetchDeviceNames()
                let renameEntity = RenameActionEntity(
                    deviceId: device.id,
                    deviceOldName: device.name,
                    otherDeviceNames: deviceNames) { [weak self] in
                        DispatchQueue.main.async {
                            self?.refreshDevicesPublisher?.send()
                        }
                }
                deviceCenterBridge.renameActionTapped(renameEntity)
            default: break
            }
        }
    }
    
    func backupStatusDetailedErrorMessage() -> String? {
        guard case let .backup(backup) = itemType,
              backup.backupStatus == .error else { return nil }
        switch backup.substate {
        case .unknownError: return Strings.Localizable.Device.Center.Backup.Error.unknown
        case .unsupportedFileSystem: return Strings.Localizable.Device.Center.Backup.Error.fileSystemUnsupported
        case .invalidRemoteType: return Strings.Localizable.Device.Center.Backup.Error.folderCantSync
        case .invalidLocalType: return Strings.Localizable.Device.Center.Backup.Error.fileSyncIndividual
        case .initialScanFailed: return Strings.Localizable.Device.Center.Backup.Error.initialScanFailed
        case .localPathTemporaryUnavailable: return Strings.Localizable.Device.Center.Backup.Error.folderDeviceUnlocatedNow
        case .localPathUnavailable: return Strings.Localizable.Device.Center.Backup.Error.folderDeviceUnlocated
        case .remoteNodeNotFound: return Strings.Localizable.Device.Center.Backup.Error.folderMegaMovedOrDeleted
        case .storageOverquota: return Strings.Localizable.Device.Center.Backup.Error.storageQuotaReached
        case .accountExpired: return Strings.Localizable.Device.Center.Backup.Error.planExpired
        case .foreignTargetOverstorage: return Strings.Localizable.Device.Center.Backup.Error.userSharedQuotaReached
        case .remotePathHasChanged: return Strings.Localizable.Device.Center.Backup.Error.folderMegaMovedOrDeleted
        case .shareNonFullAccess: return Strings.Localizable.Device.Center.Backup.Error.sharedFolderNoFullAccess
        case .localFilesystemMismatch: return Strings.Localizable.Device.Center.Backup.Error.filesInFolder
        case .putNodesError: return Strings.Localizable.Device.Center.Backup.Error.filesInFolder
        case .activeSyncBelowPath: return Strings.Localizable.Device.Center.Backup.Error.containsSyncedFolders
        case .activeSyncAbovePath: return Strings.Localizable.Device.Center.Backup.Error.insideSyncedFolder
        case .remoteNodeMovedToRubbish: return Strings.Localizable.Device.Center.Backup.Error.folderInRubbish
        case .remoteNodeInsideRubbish: return Strings.Localizable.Device.Center.Backup.Error.folderInRubbish
        case .vBoxSharedFolderUnsupported: return Strings.Localizable.Device.Center.Backup.Error.virtualboxFolders
        case .localPathSyncCollision: return Strings.Localizable.Device.Center.Backup.Error.insideSyncedFolder
        case .accountBlocked: return Strings.Localizable.Device.Center.Backup.Error.accountBlocked
        case .unknownTemporaryError: return Strings.Localizable.Device.Center.Backup.Error.problemSyncingContactSupport
        case .tooManyActionPackets: return Strings.Localizable.Device.Center.Backup.Error.accountReloaded
        case .loggedOut: return Strings.Localizable.Device.Center.Backup.Error.loggedOut
        case .wholeAccountRefetched: return Strings.Localizable.Device.Center.Backup.Error.accountReloaded
        case .backupModified: return Strings.Localizable.Device.Center.Backup.Error.changesToMegaFolder
        case .backupSourceNotBelowDrive: return Strings.Localizable.Device.Center.Backup.Error.externalDriveUnlocated
        case .syncConfigWriteFailure: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .activeSyncSamePath: return Strings.Localizable.Device.Center.Backup.Error.alreadySyncedPath
        case .couldNotMoveCloudNodes: return Strings.Localizable.Device.Center.Backup.Error.renamingFailed
        case .couldNotCreateIgnoreFile: return Strings.Localizable.Device.Center.Backup.Error.syncIgnored
        case .syncConfigReadFailure: return Strings.Localizable.Device.Center.Backup.Error.couldntReadSyncConfig
        case .unknownDrivePath: return Strings.Localizable.Device.Center.Backup.Error.unknownDrivePath
        case .invalidScanInterval: return Strings.Localizable.Device.Center.Backup.Error.invalidScanInterval
        case .notificationSystemUnavailable: return Strings.Localizable.Device.Center.Backup.Error.communicateWithFolderLocation
        case .unableToAddWatch: return Strings.Localizable.Device.Center.Backup.Error.addFilesystemWatch
        case .unableToRetrieveRootFSID: return Strings.Localizable.Device.Center.Backup.Error.cantReadSyncLocation
        case .unableToOpenDatabase: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .insufficientDiskSpace: return Strings.Localizable.Device.Center.Backup.Error.insufficientDownloadSpace
        case .failureAccessingPersistentStorage: return Strings.Localizable.Device.Center.Backup.Error.cantReadSyncLocation
        case .mismatchOfRootRSID: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .filesystemFileIdsAreUnstable: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .filesystemIDUnavailable: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        default: return nil
        }
    }
}
