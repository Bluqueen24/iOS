@testable import MEGA
@testable import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

@MainActor
final class PhotosViewModelTests: XCTestCase {
    var sut: PhotosViewModel!
    
    override func setUp() {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let allPhotos = sampleNodesForAllLocations()
        let allPhotosForCloudDrive = sampleNodesForCloudDriveOnly()
        let allPhotosForCameraUploads = sampleNodesForCameraUploads()
        let usecase = MockPhotoLibraryUseCase(allPhotos: allPhotos,
                                              allPhotosFromCloudDriveOnly: allPhotosForCloudDrive,
                                              allPhotosFromCameraUpload: allPhotosForCameraUploads)
        sut = PhotosViewModel(
            photoUpdatePublisher: publisher,
            photoLibraryUseCase: usecase,
            userAttributeUseCase: MockUserAttributeUseCase(
                contentConsumption: ContentConsumptionEntity(
                    ios: ContentConsumptionIos(timeline: ContentConsumptionTimeline(mediaType: .images, location: .cloudDrive, usePreference: true)))),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(), 
            devicePermissionHandler: MockDevicePermissionHandler(),
            cameraUploadsSettingsViewRouter: MockCameraUploadsSettingsViewRouter())
    }
    
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsModificationDesc_shouldReturnNewest() async throws {
                
        let givenSortOrder = SortOrderEntity.modificationDesc
        
        // Arrange
        let sut = makePhotosViewModel(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: givenSortOrder))
        // Act
        let result = await sut.$cameraUploadExplorerSortOrderType.values.first { @Sendable sort in sort == .newest }
        // Assert
        XCTAssertEqual(result, .newest)
    }
    
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsModificationAsc_shouldReturnOldest() async throws {
        
        let givenSortOrder = SortOrderEntity.modificationAsc
        
        // Arrange
        let sut = makePhotosViewModel(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: givenSortOrder))
        // Act
        let result = await sut.$cameraUploadExplorerSortOrderType
            .values
            .first { @Sendable sort in sort == .oldest }
        // Assert
        XCTAssertEqual(result, .oldest)
    }
    
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsNonModificationType_shouldReturnNewest() async throws {
                
        let givenSortOrder = SortOrderEntity.favouriteAsc
        
        // Arrange
        let sut = makePhotosViewModel(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: givenSortOrder))
        // Act
        let result = await sut.$cameraUploadExplorerSortOrderType.values.first { @Sendable sort in sort == .newest }
        // Assert
        XCTAssertEqual(result, .newest)
    }
    
    // MARK: - All locations test cases
    
    func testLoadingPhotos_withAllMediaAllLocations_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForAllLocations()
        sut.filterType = .allMedia
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    func testLoadingPhotos_withAllMediaAllLocations_shouldExcludeThumbnailLessPhotos() async throws {
        let photos = [
            NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 0, hasThumbnail: true),
            NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true),
            NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 2, hasThumbnail: false),
            NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 3, hasThumbnail: false),
            NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 5, parentHandle: 4, hasThumbnail: true)
        ]
        
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let usecase = MockPhotoLibraryUseCase(allPhotos: photos,
                                              allPhotosFromCloudDriveOnly: [],
                                              allPhotosFromCameraUpload: [])
        sut = PhotosViewModel(
            photoUpdatePublisher: publisher,
            photoLibraryUseCase: usecase,
            userAttributeUseCase: MockUserAttributeUseCase(),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(),
            devicePermissionHandler: MockDevicePermissionHandler(),
            cameraUploadsSettingsViewRouter: MockCameraUploadsSettingsViewRouter())
        
        sut.filterType = .allMedia
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, photos.filter { $0.hasThumbnail })
    }
    
    func testLoadingPhotos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForAllLocations().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    func testLoadingVideos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForAllLocations().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    // MARK: - Cloud Drive only test cases
    
    func testLoadingPhotos_withAllMediaFromCloudDrive_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCloudDriveOnly()
        sut.filterType = .allMedia
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    func testLoadingPhotos_withImagesFromCloudDrive_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCloudDriveOnly().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    func testLoadingPhotos_withVideosFromCloudDrive_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCloudDriveOnly().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    // MARK: - Camera Uploads test cases
    
    func testLoadingPhotos_withAllMediaFromCameraUploads_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCameraUploads()
        sut.filterType = .allMedia
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    func testLoadingPhotos_withImagesFromCameraUploads_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCameraUploads().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    func testLoadingPhotos_withVideosFromCameraUploads_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCameraUploads().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    func testIsSelectHidden_onToggle_changesInitialFalseValueToTrue() {
        XCTAssertFalse(sut.isSelectHidden)
        sut.isSelectHidden.toggle()
        XCTAssertTrue(sut.isSelectHidden)
    }
    
    func testFilterType_whenCheckingSavedFilter_shouldReturnRightValues() {
        XCTAssertEqual(PhotosFilterOptions.images, sut.filterType(from: .images))
        XCTAssertEqual(PhotosFilterOptions.videos, sut.filterType(from: .videos))
        XCTAssertEqual(PhotosFilterOptions.allMedia, sut.filterType(from: .allMedia))
    }
    
    func testFilterLocation_whenCheckingSavedFilter_shouldReturnRightValues() {
        XCTAssertEqual(PhotosFilterOptions.cloudDrive, sut.filterLocation(from: .cloudDrive))
        XCTAssertEqual(PhotosFilterOptions.cameraUploads, sut.filterLocation(from: .cameraUploads))
        XCTAssertEqual(PhotosFilterOptions.allLocations, sut.filterLocation(from: .allLocations))
    }
    
    func testLoadAllPhotosWithSavedFilters_whenTheScreenAppear_shouldLoadTheExistingFilters() async {
        let useCase = MockUserAttributeUseCase(contentConsumption: ContentConsumptionEntity(ios: ContentConsumptionIos(timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: true))))
        let sut = makePhotosViewModel(userAttributeUseCase: useCase)
        
        sut.loadAllPhotosWithSavedFilters()
        await sut.contentConsumptionAttributeLoadingTask?.value
        
        XCTAssertEqual(sut.filterType, .videos)
        XCTAssertEqual(sut.filterLocation, .cloudDrive)
    }
    
    func testTimelineCameraUploadStatusFeatureEnabled_featureToggleOn_shouldReturnTrue() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.timelineCameraUploadStatus: true])
        let sut = makePhotosViewModel(featureFlagProvider: featureFlagProvider)
        
        XCTAssertTrue(sut.timelineCameraUploadStatusFeatureEnabled)
    }
    
    func testTimelineCameraUploadStatusFeatureEnabled_featureToggleOff_shouldReturnFalse() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.timelineCameraUploadStatus: false])
        let sut = makePhotosViewModel(featureFlagProvider: featureFlagProvider)
        
        XCTAssertFalse(sut.timelineCameraUploadStatusFeatureEnabled)
    }
    
    func testEmptyScreenTypeToShow_cameraUploadsOn_shouldReturnNoMedia() {
        let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        XCTAssertEqual(sut.emptyScreenTypeToShow(), .noMediaFound)
    }
    
    func testEmptyScreenTypeToShow_forFilterTypeAndLocationCameraUploadsOff_shouldReturnCorrectEmptyScreenTypeToDisplay() {
        let expectations = [(filterType: PhotosFilterOptions.allMedia,
                             filterLocation: PhotosFilterOptions.allLocations, expectedViewType: PhotosEmptyScreenViewType.enableCameraUploads),
                            (filterType: .allMedia, filterLocation: .cloudDrive, expectedViewType: .noMediaFound),
                            (filterType: .allMedia, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                            (filterType: .images, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                            (filterType: .images, filterLocation: .cloudDrive, expectedViewType: .noImagesFound),
                            (filterType: .images, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                            (filterType: .videos, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                            (filterType: .videos, filterLocation: .cloudDrive, expectedViewType: .noVideosFound),
                            (filterType: .videos, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads)
        ]
        
        for (index, value) in expectations.enumerated() {
            let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false]))
            sut.updateFilter(filterType: value.filterType, filterLocation: value.filterLocation)
            
            XCTAssertEqual(sut.emptyScreenTypeToShow(), value.expectedViewType,
                           "Failed at index: \(index) with value: \(value)")
        }
    }
    
    func testEnableCameraUploadsBannerAction_cameraUploadsOn_shouldReturnNil() {
        let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        XCTAssertNil(sut.enableCameraUploadsBannerAction())
    }
    
    func testEnableCameraUploadsBannerAction_cameraUploadsOffForFilterLocation_shouldReturnCorrectly() throws {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false]),
                                      cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        for (index, value) in [PhotosFilterOptions.allLocations, .cameraUploads].enumerated() {
            sut.updateFilter(filterType: .allMedia, filterLocation: value)
            XCTAssertNil(sut.enableCameraUploadsBannerAction(), "Failed at index: \(index) with value: \(value)")
        }
        
        sut.updateFilter(filterType: .allMedia, filterLocation: .cloudDrive)
        
        let action = try XCTUnwrap(sut.enableCameraUploadsBannerAction())
        action()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 1)
    }
    
    func testNavigateToCameraUploadSettings_called_shouldStartNavigation() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false]),
                                      cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.navigateToCameraUploadSettings()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 1)
    }
    
    func testCameraUploadStatusButtonTapped_whenCameraUploadesIsDisabled_shouldNavigateToCUSetting() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(
            preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false]),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.cameraUploadStatusButtonViewModel.onTappedHandler?()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 1)
        XCTAssertFalse(sut.timelineViewModel.cameraUploadStatusShown)
    }
    
    func testCameraUploadStatusButtonTapped_whenCameraUploadesEnabled_shouldShowCUStatusBanner() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(
            preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.cameraUploadStatusButtonViewModel.onTappedHandler?()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 0)
        XCTAssertTrue(sut.timelineViewModel.cameraUploadStatusShown)
    }
    
    private func sampleNodesForAllLocations() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 0, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 2, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 3, hasThumbnail: true)
        let node5 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 5, parentHandle: 4, hasThumbnail: true)
        let node6 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 6, parentHandle: 5, hasThumbnail: true)
        let node7 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 7, parentHandle: 6, hasThumbnail: true)
        let node8 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 8, parentHandle: 7, hasThumbnail: true)
        
        return [node1, node2, node3, node4, node5, node6, node7, node8]
    }
    
    private func sampleNodesForCloudDriveOnly() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 1, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 1, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 1, hasThumbnail: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleNodesForCameraUploads() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 1, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 1, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 1, hasThumbnail: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func makePhotosViewModel(
        userAttributeUseCase: some UserAttributeUseCaseProtocol = MockUserAttributeUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        cameraUploadsSettingsViewRouter: some Routing = MockCameraUploadsSettingsViewRouter(),
        monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> PhotosViewModel {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let usecase = MockPhotoLibraryUseCase(allPhotos: [],
                                              allPhotosFromCloudDriveOnly: [],
                                              allPhotosFromCameraUpload: [])
        return PhotosViewModel(photoUpdatePublisher: publisher,
                               photoLibraryUseCase: usecase,
                               userAttributeUseCase: userAttributeUseCase,
                               sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
                               preferenceUseCase: preferenceUseCase,
                               monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                               devicePermissionHandler: MockDevicePermissionHandler(),
                               cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
                               featureFlagProvider: featureFlagProvider)
    }
}

private class MockCameraUploadsSettingsViewRouter: Routing {
    private(set) var startCalled = 0
    
    func start() {
        startCalled += 1
    }
}
