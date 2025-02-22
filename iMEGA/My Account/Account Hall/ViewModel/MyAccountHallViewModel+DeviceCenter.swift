import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI

extension MyAccountHallViewModel {
    func makeDeviceCenterBridge() {
        deviceCenterBridge.cameraUploadActionTapped = { [weak self] cameraUploadStatusChanged in
            self?.router.didTapCameraUploadsAction(statusChanged: cameraUploadStatusChanged)
        }
        
        deviceCenterBridge.renameActionTapped = { [weak self] renameEntity in
            self?.router.didTapRenameAction(renameEntity)
        }
        
        deviceCenterBridge.infoActionTapped = { [weak self] resourceInfoModel in
            self?.router.didTapInfoAction(resourceInfoModel)
        }
        
        deviceCenterBridge.showInTapped = { [weak self] showInActionEntity in
            self?.router.didTapNavigateToContent(showInActionEntity)
        }
    }
    
    func makeDeviceCenterAssetData() -> DeviceCenterAssets {
        DeviceCenterAssets(
            deviceListAssets:
                makeDeviceListAssets(),
            backupListAssets:
                makeBackupListAssets(),
            emptyStateAssets:
                makeEmptyStateAssets(),
            searchAssets:
                makeSearchAssets(),
            backupStatuses: backupStatusesList(),
            deviceCenterActions: deviceCenterActionList(),
            deviceIconNames: deviceIconNamesList()
        )
    }
    
    private func makeDeviceListAssets() -> DeviceListAssets {
        return DeviceListAssets(
            title: Strings.Localizable.Device.Center.title,
            currentDeviceTitle: Strings.Localizable.Device.Center.Current.Device.title,
            otherDevicesTitle: Strings.Localizable.Device.Center.Other.Devices.title,
            deviceDefaultName: Strings.Localizable.Device.Center.Default.Device.title
        )
    }
    
    private func makeBackupListAssets() -> BackupListAssets {
        return BackupListAssets(
            backupTypes: [
                BackupType(type: .backupUpload, iconName: BackUpTypeIconAssets.backupFolder),
                BackupType(type: .cameraUpload, iconName: BackUpTypeIconAssets.cameraUploadsFolder),
                BackupType(type: .mediaUpload, iconName: BackUpTypeIconAssets.cameraUploadsFolder),
                BackupType(type: .twoWay, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .downSync, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .upSync, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .invalid, iconName: BackUpTypeIconAssets.syncFolder)
            ]
        )
    }
    
    private func makeEmptyStateAssets() -> EmptyStateAssets {
        return EmptyStateAssets(
            image: EmptyStateIconAssets.searchEmptyState,
            title: Strings.Localizable.noResults
        )
    }
    
    private func makeSearchAssets() -> SearchAssets {
        return SearchAssets(
            placeHolder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel,
            lightBGColor: MEGAAppColor.White._F7F7F7.color,
            darkBGColor: MEGAAppColor.Black._161616.color
        )
    }
    
    private func backupStatusesList() -> [BackupStatus] {
        return [
            BackupStatus(
                status: .upToDate,
                title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                color: MEGAAppColor.Green._34C759.uiColor,
                iconName: BackUpStatusIconAssets.upToDate
            ),
            BackupStatus(
                status: .scanning,
                title: Strings.Localizable.Device.Center.Backup.Scanning.Status.message,
                color: MEGAAppColor.Blue._007AFF.uiColor,
                iconName: BackUpStatusIconAssets.updating
            ),
            BackupStatus(
                status: .initialising,
                title: Strings.Localizable.Device.Center.Backup.Initialising.Status.message,
                color: MEGAAppColor.Blue._007AFF.uiColor,
                iconName: BackUpStatusIconAssets.updating
            ),
            BackupStatus(
                status: .updating,
                title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                color: MEGAAppColor.Blue._007AFF.uiColor,
                iconName: BackUpStatusIconAssets.updating
            ),
            BackupStatus(
                status: .noCameraUploads,
                title: Strings.Localizable.Device.Center.Backup.NoCameraUploads.Status.message,
                color: MEGAAppColor.Orange._FF9500.uiColor,
                iconName: BackUpStatusIconAssets.noCameraUploads
            ),
            BackupStatus(
                status: .disabled,
                title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
                color: MEGAAppColor.Orange._FF9500.uiColor,
                iconName: BackUpStatusIconAssets.disabled
            ),
            BackupStatus(
                status: .offline,
                title: Strings.Localizable.Device.Center.Backup.Offline.Status.message,
                color: MEGAAppColor.Gray._8E8E93.uiColor,
                iconName: BackUpStatusIconAssets.offlineStatus
            ),
            BackupStatus(
                status: .backupStopped,
                title: Strings.Localizable.Device.Center.Backup.BackupStopped.Status.message,
                color: MEGAAppColor.Gray._8E8E93.uiColor,
                iconName: BackUpStatusIconAssets.error
            ),
            BackupStatus(
                status: .paused,
                title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
                color: MEGAAppColor.Gray._8E8E93.uiColor,
                iconName: BackUpStatusIconAssets.paused
            ),
            BackupStatus(
                status: .outOfQuota,
                title: Strings.Localizable.Device.Center.Backup.OutOfQuota.Status.message,
                color: MEGAAppColor.Red._FF3B30.uiColor,
                iconName: BackUpStatusIconAssets.outOfQuota
            ),
            BackupStatus(
                status: .error,
                title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
                color: MEGAAppColor.Red._FF3B30.uiColor,
                iconName: BackUpStatusIconAssets.error
            ),
            BackupStatus(
                status: .blocked,
                title: Strings.Localizable.Device.Center.Backup.Blocked.Status.message,
                color: MEGAAppColor.Red._FF3B30.uiColor,
                iconName: BackUpStatusIconAssets.disabled
            )
        ]
    }
    
    private func deviceCenterActionList() -> [DeviceCenterAction] {
        return [
            DeviceCenterAction(
                type: .cameraUploads,
                title: Strings.Localizable.cameraUploadsLabel,
                dynamicSubtitle: {
                    CameraUploadManager.isCameraUploadEnabled ? Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
                        Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled
                },
                icon: DeviceCenterActionIconAssets.cameraUploadsSettings
            ),
            DeviceCenterAction(
                type: .info,
                title: Strings.Localizable.info,
                icon: DeviceCenterActionIconAssets.info
            ),
            DeviceCenterAction(
                type: .rename,
                title: Strings.Localizable.rename,
                icon: DeviceCenterActionIconAssets.rename
            ),
            DeviceCenterAction(
                type: .sort,
                title: Strings.Localizable.sortTitle,
                icon: DeviceCenterActionIconAssets.sort,
                subActions: [
                    DeviceCenterAction(
                        type: .sortAscending,
                        title: Strings.Localizable.nameAscending,
                        icon: DeviceCenterActionIconAssets.ascending
                    ),
                    DeviceCenterAction(
                        type: .sortDescending,
                        title: Strings.Localizable.nameDescending,
                        icon: DeviceCenterActionIconAssets.descending
                    ),
                    DeviceCenterAction(
                        type: .sortLargest,
                        title: Strings.Localizable.largest,
                        icon: DeviceCenterActionIconAssets.largest
                    ),
                    DeviceCenterAction(
                        type: .sortSmallest,
                        title: Strings.Localizable.smallest,
                        icon: DeviceCenterActionIconAssets.smallest
                    ),
                    DeviceCenterAction(
                        type: .sortNewest,
                        title: Strings.Localizable.newest,
                        icon: DeviceCenterActionIconAssets.newest
                    ),
                    DeviceCenterAction(
                        type: .sortOldest,
                        title: Strings.Localizable.oldest,
                        icon: DeviceCenterActionIconAssets.oldest
                    ),
                    DeviceCenterAction(
                        type: .sortLabel,
                        title: Strings.Localizable.CloudDrive.Sort.label,
                        icon: DeviceCenterActionIconAssets.label
                    ),
                    DeviceCenterAction(
                        type: .sortFavourite,
                        title: Strings.Localizable.favourite,
                        icon: DeviceCenterActionIconAssets.favourite
                    )
                ]
            )
        ]
    }
    
    private func deviceIconNamesList() -> [BackupDeviceTypeEntity: String] {
        [
            .android: DeviceIconAssets.android,
            .iphone: DeviceIconAssets.ios,
            .linux: DeviceIconAssets.pcLinux,
            .mac: DeviceIconAssets.pcMac,
            .win: DeviceIconAssets.pcWindows,
            .defaultMobile: DeviceIconAssets.mobile,
            .defaultPc: DeviceIconAssets.pc
        ]
    }
    
    private struct DeviceIconAssets {
        static let android = "android"
        static let ios = "ios"
        static let pcLinux = "pc-linux"
        static let pcMac = "pc-mac"
        static let pcWindows = "pc-windows"
        static let mobile = "mobile"
        static let pc = "pc"
    }
    
    private struct DeviceCenterActionIconAssets {
        static let cameraUploadsSettings = "cameraUploadsSettings"
        static let info = "info"
        static let rename = "rename"
        static let cloudDriveFolder = "cloudDriveFolder"
        static let sort = "sort"
        static let ascending = "ascending"
        static let descending = "descending"
        static let largest = "largest"
        static let smallest = "smallest"
        static let newest = "newest"
        static let oldest = "oldest"
        static let label = "label"
        static let favourite = "favourite"
    }
    
    private struct BackUpStatusIconAssets {
        static let upToDate = "backUpStatusUpToDate"
        static let updating = "backUpStatusUpdating"
        static let noCameraUploads = "backUpStatusNoCameraUploads"
        static let disabled  = "backUpStatusDisabled"
        static let offlineStatus = "backUpStatusOfflineStatus"
        static let error = "backUpStatusError"
        static let paused = "backUpStatusPaused"
        static let outOfQuota = "backUpStatusOutOfQuota"
    }
    
    private struct BackUpTypeIconAssets {
        static let backupFolder = "backupFolder"
        static let cameraUploadsFolder = "cameraUploadsFolder"
        static let syncFolder = "syncFolder"
    }
    
    private struct EmptyStateIconAssets {
        static let searchEmptyState = "searchEmptyState"
    }
}
