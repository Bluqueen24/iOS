import MEGADomain
import MEGAPermissions

extension CameraUploadManager {
    @objc func scheduleCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.schedule()
    }
    
    @objc func cancelCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.cancel()
    }
    
    private class var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc
    class func disableCameraUploadIfAccessProhibited() {
        if
            permissionHandler.isPhotoLibraryAccessProhibited,
            Self.isCameraUploadEnabled
        {
            Self.shared().disableCameraUpload()
        }
    }
    
    @objc
    func initializeCameraUploadHeartbeat() {
        let cameraUploadsUseCase = CameraUploadsUseCase(
            cameraUploadsRepository: CameraUploadsRepository.newRepo
        )
        
        self.heartbeat = CameraUploadHeartbeat(
            cameraUploadsUseCase: cameraUploadsUseCase
        )
    }
}
