import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import XCTest

@MainActor
final class AlbumListViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadAlbums_onAlbumsLoaded_systemAlbumsTitlesAreUpdatedAndAlbumsAreSortedCorrectly() async throws {
        var favouriteAlbum = AlbumEntity(id: 1, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .favourite)
        var gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        var rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:01:04Z".date)
        let userAlbum2 = AlbumEntity(id: 5, name: "Album 2", coverNode: NodeEntity(handle: 4),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:02:04Z".date)
        let userAlbum3 = AlbumEntity(id: 6, name: "Other Album 1", coverNode: NodeEntity(handle: 5),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:03:04Z".date)
        let userAlbum4 = AlbumEntity(id: 7, name: "Other Album 4", coverNode: NodeEntity(handle: 6),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:04:04Z".date)
        let userAlbum5 = AlbumEntity(id: 8, name: "Album 5", coverNode: NodeEntity(handle: 7),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:05:04Z".date)
        let useCase = MockAlbumListUseCase(albums: [favouriteAlbum, gifAlbum, rawAlbum,
                                                    userAlbum1, userAlbum2, userAlbum3, userAlbum4, userAlbum5])
        // Update titles to expected
        favouriteAlbum.name = Strings.Localizable.CameraUploads.Albums.Favourites.title
        gifAlbum.name = Strings.Localizable.CameraUploads.Albums.Gif.title
        rawAlbum.name = Strings.Localizable.CameraUploads.Albums.Raw.title
        let sut = albumListViewModel(usecase: useCase)
        
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        
        XCTAssertEqual(sut.albums, [
            favouriteAlbum,
            gifAlbum,
            rawAlbum,
            userAlbum5,
            userAlbum4,
            userAlbum3,
            userAlbum2,
            userAlbum1
        ])
    }
    
    func testLoadAlbums_onAlbumsLoadedFinished_shouldLoadSetToFalse() async throws {
        let sut = albumListViewModel()
        let exp = expectation(description: "should load set after album load")
        
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func testHasCustomAlbum_whenUserLoadAlbums_shouldReturnTrue() async throws {
        let rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user)
        let mockAlbumUseCase = MockAlbumListUseCase(albums: [rawAlbum, userAlbum1])
                                     
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: mockAlbumUseCase, photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        
        XCTAssertTrue(photoAlbumContainerViewModel.shouldShowSelectBarButton)
    }
    
    func testCreateUserAlbum_shouldCreateUserAlbum() {
        let exp = expectation(description: "Create a new user album")
        let sut = albumListViewModel()
        sut.createUserAlbum(with: "userAlbum")
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        wait(for: [exp], timeout: 2.0)
    }
    
    func testHasCustomAlbum_whenUserCreateNewAlbum_shouldReturnTrue() {
        let exp = expectation(description: "Should set hasCustomAlbut to true when user create a new album")
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        sut.createUserAlbum(with: "userAlbum")
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(photoAlbumContainerViewModel.shouldShowSelectBarButton)
    }
    
    func testCreateUserAlbum_whenUserCreatingAnAlbum_setShouldShowSelectBarButtonToFalse() async throws {
        let newAlbumName = "New Album"
        let newUserAlbum = AlbumEntity(id: 1, name: newAlbumName, coverNode: nil,
                                       count: 0, type: .user, modificationTime: try "2023-01-16T11:01:04Z".date)
        let useCase = MockAlbumListUseCase(albums: [], createdUserAlbums: [newAlbumName: newUserAlbum])
        
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: useCase, photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        sut.createUserAlbum(with: newAlbumName)
        XCTAssertTrue(photoAlbumContainerViewModel.disableSelectBarButton)
        await sut.createAlbumTask?.value
        XCTAssertFalse(photoAlbumContainerViewModel.disableSelectBarButton)
    }
    
    func testNewAlbumName_whenAlbumContainsNoNewAlbum() async {
        let sut = albumListViewModel()
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
    }
    
    func testNewAlbumName_whenAlbumContainsNewAlbum() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " \("(1)")")
    }
    
    func testNewAlbumName_whenAlbumContainsSomeNewAlbums_shouldReturnTheCorrectSuffix() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let newAlbum1 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (1)")
        
        let newAlbum3 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (3)")
        
        let newAlbum4 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + "Some Random name")
        
        let useCase = MockAlbumListUseCase(albums: [newAlbum4, newAlbum, newAlbum1, newAlbum3])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        
        let newAlbumNameShouldBe = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (2)"
        
        XCTAssertEqual(sut.newAlbumName(), newAlbumNameShouldBe)
    }
    
    func testNewAlbumName_whenAlbumContainsSomeNewAlbumsButNotNewAlbum_shouldReturnNewAlbum() async {
        let newAlbum1 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (1)")
        
        let newAlbum3 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (3)")
        
        let newAlbum4 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + "Some Random name")
        
        let useCase = MockAlbumListUseCase(albums: [newAlbum4, newAlbum1, newAlbum3])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        
        let newAlbumNameShouldBe = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        
        XCTAssertEqual(sut.newAlbumName(), newAlbumNameShouldBe)
    }
    
    func testNewAlbumNamePlaceholderText_whenAlbumContainsNewAlbum_shouldReturnCounterSuffix() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        sut.showCreateAlbumAlert = true
        
        XCTAssertEqual(sut.alertViewModel.placeholderText, "New album (1)")
    }
    
    func testValidateAlbum_whenAlbumNameIsNil_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?(nil))
    }
    
    func testValidateAlbum_whenAlbumNameIsEmpty_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?(""))
    }
    
    func testValidateAlbum_whenAlbumNameIsSpaces_returnsError() {
        let sut = albumListViewModel()
        XCTAssertNotNil(sut.alertViewModel.validator?("      "))
    }
    
    func testValidateAlbum_whenAlbumNameIsValidButWithWhiteSpaces_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?("  userAlbum    "))
    }
    
    func testValidateAlbum_whenAlbumNameIsValid_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?("userAlbum"))
    }
    
    func testValidateAlbum_whenAlbumNameContainsInvalidChars_returnsErrorMessage() {
        let sut = albumListViewModel()
        XCTAssertNotNil(sut.alertViewModel.validator?("userAlbum:/;"))
    }
    
    func testValidateAlbum_whenAlbumNameIsSameAsExistingUserAlbum_returnsErrorMessage() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: "userAlbum")
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertNotNil(sut.alertViewModel.validator?(newAlbum.name))
    }
    
    func testValidateAlbum_whenAlbumNameIsSameAsExistingSystemAlbum_returnsErrorMessage() async {
        let newSysAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                      coverNode: NodeEntity(handle: AlbumIdEntity.favourite.rawValue), count: 0, type: .favourite)
        let useCase = MockAlbumListUseCase(albums: [newSysAlbum])
        let sut = albumListViewModel(usecase: useCase)
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertNotNil(sut.alertViewModel.validator?(newSysAlbum.name))
    }
    
    func testOnAlbumContentAdded_whenContentAddedInNewAlbum_shouldReloadAlbums() async {
        let sut = albumListViewModel()

        let sampleAlbum = AlbumEntity(id: 1, name: "hello", coverNode: nil, count: 0, type: .user)
        let nodes = [NodeEntity(handle: 1)]
        sut.onNewAlbumContentAdded(sampleAlbum, photos: nodes)
        
        XCTAssertEqual(sut.newAlbumContent?.album, sampleAlbum)
        XCTAssertEqual(sut.newAlbumContent?.photos, nodes)
    }
    
    func testValidateAlbum_withSystemAlbumNames_returnsErrorMessage() {
        let reservedNames = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                             Strings.Localizable.CameraUploads.Albums.Gif.title,
                             Strings.Localizable.CameraUploads.Albums.Raw.title,
                             Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                             Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]
        let sut = albumListViewModel()
        reservedNames.forEach { name in
            XCTAssertNotNil(sut.alertViewModel.validator?(name))
        }
    }
    
    func testColumns_sizeConfigurationsChangesReturnCorrectColumns() {
        let sut = albumListViewModel()
        XCTAssertEqual(sut.columns(horizontalSizeClass: .compact).count, 3)
        XCTAssertEqual(sut.columns(horizontalSizeClass: nil).count, 3)
        XCTAssertEqual(sut.columns(horizontalSizeClass: .regular).count, 5)
    }
    
    func testNavigateToNewAlbum_onNewAlbumContentAdded_shouldNavigateToAlbumContentIfSet() {
        let sut = albumListViewModel()
        let userAlbum = AlbumEntity(id: 1, name: "User", coverNode: nil, count: 0, type: .user)
        let newAlbumPhotos = [NodeEntity(name: "a.jpg", handle: 1, modificationTime: Date.distantFuture),
                              NodeEntity(name: "b.jpg", handle: 2, modificationTime: Date.distantPast)]
        
        let modifiedAlbum = AlbumEntity(id: 1, name: "User", coverNode: newAlbumPhotos.first, count: 2, type: .user)
        
        sut.onNewAlbumContentAdded(userAlbum, photos: newAlbumPhotos)
        sut.navigateToNewAlbum()
        
        XCTAssertEqual(sut.album, modifiedAlbum)
        XCTAssertEqual(sut.newAlbumContent?.photos, newAlbumPhotos)
        XCTAssertEqual(sut.album?.count, newAlbumPhotos.count)
        XCTAssertEqual(sut.album?.coverNode, newAlbumPhotos.first)
    }
    
    func testNavigateToNewAlbum_onNewAlbumContentAddedNotCalled_shouldNotNavigate() {
        let sut = albumListViewModel()
        
        sut.navigateToNewAlbum()
        XCTAssertNil(sut.album)
        XCTAssertNil(sut.newAlbumContent)
    }
    
    func testOnAlbumTap_whenUserTap_shouldSetCorrectValues() {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        
        sut.onAlbumTap(gifAlbum)
        XCTAssertNil(sut.albumCreationAlertMsg)
        XCTAssertEqual(sut.album, gifAlbum)
        
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                gifAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    func testOnAlbumTap_notInEditMode_shouldSendSelectedEvent() {
        let userAlbum = AlbumEntity(id: 5, type: .user,
                                    metaData: AlbumMetaDataEntity(
                                        imageCount: 6,
                                        videoCount: 8))
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        sut.onAlbumTap(userAlbum)
        
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                userAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    func testOnCreateAlbum_whenIsEditModeActive_shouldReturnFalseForShowCreateAlbumAlert() {
        let sut = albumListViewModel()
        
        sut.selection.editMode = .active
        XCTAssertFalse(sut.showCreateAlbumAlert)
        sut.onCreateAlbum()
        XCTAssertFalse(sut.showCreateAlbumAlert)
    }
    
    func testOnCreateAlbum_whenIsEditModeNotActive_shouldToggleShowCreateAlbumAlert() {
        let sut = albumListViewModel()
        
        XCTAssertFalse(sut.showCreateAlbumAlert)
        sut.onCreateAlbum()
        XCTAssertTrue(sut.showCreateAlbumAlert)
    }
    
    func testAlbumNames_whenExistingAlbumNamesNeeded_shouldReturnAlbumNames() async {
        let album1 = AlbumEntity(id: 1, name: "Hey there", coverNode: nil, count: 0, type: .user)
        let album2 = AlbumEntity(id: 1, name: "", coverNode: nil, count: 0, type: .user)
        let album3 = AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite)
        
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: [album1, album2, album3]))
        sut.loadAlbums()
        await sut.albumLoadingTask?.value
        
        XCTAssertEqual(sut.albumNames.sorted(), ["Hey there", "", "Favourites"].sorted())
    }
    
    func testReloadUpdates_onAlbumsUpdateEmitted_shouldReloadAlbums() {
        let albums = [AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                  count: 1, type: .user)]
        let albumsUpdatedPublisher = PassthroughSubject<Void, Never>()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums,
                                                                   albumsUpdatedPublisher: albumsUpdatedPublisher.eraseToAnyPublisher()))
        
        sut.onViewAppeared()
        
        XCTAssertTrue(sut.albums.isEmpty)
        
        let exp = expectation(description: "should retrieve albums")
        sut.$albums
            .dropFirst()
            .sink {
                XCTAssertEqual($0, albums)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumsUpdatedPublisher.send()
        wait(for: [exp], timeout: 2.0)
    }
    
    func testShowDeleteAlbumAlert_whenUserTapOnDeleteButton_shouldSetShowDeleteAlbumAlertToTrue() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumAlertType)
        photoAlbumContainerViewModel.showDeleteAlbumAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .deleteAlbum)
    }
    
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedSuccessfully_shouldDeleteMultipleAlbums() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums),
                                     albumModificationUseCase: MockAlbumModificationUseCase(albums: albums),
                                     photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        
        await sut.deleteAlbumTask?.value
        
        let targetMsg = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(albums.count)
        
        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: Asset.Images.Hud.hudMinus.image))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedSuccessfully_shouldDeleteSingleAlbum() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums),
                                     albumModificationUseCase: MockAlbumModificationUseCase(albums: albums),
                                     photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        await sut.deleteAlbumTask?.value
        
        let targetMsg = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(albums.count)
        
        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: Asset.Images.Hud.hudMinus.image))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedFailed_shouldDoNothing() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(), photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        sut.selection.setSelectedAlbums(albums)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        await sut.deleteAlbumTask?.value
        
        XCTAssertNil(sut.albumHudMessage)
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    func testNumOfSelectedAlbums_onAlbumSelectionChanged_shouldSetIsAlbumSelected() {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertFalse(photoAlbumContainerViewModel.isAlbumsSelected)
        
        sut.selection.setSelectedAlbums(albums)
        XCTAssertTrue(photoAlbumContainerViewModel.isAlbumsSelected)
    }
    
    func testShowDeleteAlbumAlert_whenUserTapDeleteButton_shouldSetShowAlertToTrueAndAlertTypeToDeleteAlbum() async {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        photoAlbumContainerViewModel.showDeleteAlbumAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .deleteAlbum)
    }
    
    func testIsExportedAlbumSelected_onExportedAlbumSelected_shouldSetIsExportedAlbumSelected() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isExportedAlbumSelected)
        let exportedUserAlbum = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        sut.selection.setSelectedAlbums([exportedUserAlbum])
        XCTAssertTrue(photoAlbumContainerViewModel.isExportedAlbumSelected)
    }
    
    func testIsAllExportedAlbumSelected_onExportedAlbumSelected_shouldSetisAllExportedAlbumSelectedToTrue() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
        let exportedUserAlbum1 = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        let exportedUserAlbum2 = AlbumEntity(id: 4, type: .user, sharedLinkStatus: .exported(true))
        sut.selection.setSelectedAlbums([exportedUserAlbum1, exportedUserAlbum2])
        XCTAssertTrue(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
    }
    
    func testIsAllExportedAlbumSelected_onExportedAlbumSelected_shouldSetisAllExportedAlbumSelectedToFalse() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
        let exportedUserAlbum1 = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        let normalAlbum = AlbumEntity(id: 4, type: .user)
        sut.selection.setSelectedAlbums([exportedUserAlbum1, normalAlbum])
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
    }
    
    func testShowAlbumRemoveShareLinkAlert_whenUserTapRemoveLinkButton_shouldSetShowAlertToTrueAndAlertTypeToRemoveAlbumShareLink() async {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        photoAlbumContainerViewModel.showRemoveAlbumLinksAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .removeAlbumShareLink)
    }
    
    func testOnShareLinkRemoveConfirm_whenAllAlbumShareLinkRemoveSuccessfully_shouldShowMultipleAlbumLinkDeleteHudMessage() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user)]

        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(shareAlbumUseCase: MockShareAlbumUseCase(successfullyRemoveSharedAlbumLinkIds: [HandleEntity(1), HandleEntity(2)]), photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        XCTAssertNil(sut.albumHudMessage)
        sut.onAlbumShareLinkRemoveConfirm(albums)
        await sut.albumRemoveShareLinkTask?.value

        let targetMsg = Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(albums.count)

        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: Asset.Images.Hud.hudSuccess.image))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    func testOnShareLinkRemoveConfirm_whenSomeAlbumShareLinkRemoveSuccessfully_shouldShowSingleAlbumLinkDeleteHudMessage() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user),
                      AlbumEntity(id: HandleEntity(3), name: "GHI", coverNode: nil, count: 4, type: .user)]
        
        let succesfullyDeleteAlbum = albums[0]

        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(shareAlbumUseCase: MockShareAlbumUseCase(successfullyRemoveSharedAlbumLinkIds: [succesfullyDeleteAlbum.id]), photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        XCTAssertNil(sut.albumHudMessage)
        sut.onAlbumShareLinkRemoveConfirm(albums)
        await sut.albumRemoveShareLinkTask?.value

        let targetMsg = Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1)

        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: Asset.Images.Hud.hudSuccess.image))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    func testShowAlbumLinks_onShowShareAlbumsFired_shouldTrigger() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(sut.showShareAlbumLinks)
        
        photoAlbumContainerViewModel.showShareAlbumLinks = true
        
        XCTAssertTrue(sut.showShareAlbumLinks)
    }
    
    func testSelectedUserAlbums_onAlbumsSelected_shouldOnlyReturnUseAlbums() {
        let sut = albumListViewModel()
        XCTAssertTrue(sut.selectedUserAlbums.isEmpty)
        
        let userAlbum = AlbumEntity(id: 5, type: .user)
        sut.selection.setSelectedAlbums([AlbumEntity(id: 7, type: .favourite), userAlbum])
        XCTAssertEqual(sut.selectedUserAlbums, [userAlbum])
    }
    
    func testSetEditModeToInactive_onCalled_shouldSetContainerViewModelEditModeToInactive() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        photoAlbumContainerViewModel.editMode = .active
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        sut.setEditModeToInactive()
        XCTAssertEqual(photoAlbumContainerViewModel.editMode, .inactive)
    }

    func testOnViewAppeared_whenCalled_startAlbumsUpdatedSubscription() {
        let sut = albumListViewModel()
        var isViewVisible = false
        let exp = expectation(description: "Wait for subscription")
        sut.viewIsVisiblePublisher
            .sink { isVisible in
                isViewVisible = isVisible
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.onViewAppeared()
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertTrue(isViewVisible, "Expect view is visible.")
        XCTAssertNotNil(sut.albumLoadingTask, "Expect to initialize albumLoadingTask, but not initialized instead.")
    }
    
    func testOnViewDisappeared_whenCalled_releasesAlbumsUpdatedSubscription() {
        let sut = albumListViewModel()
        var isViewVisible = false
        let exp = expectation(description: "Wait for subscription")
        sut.viewIsVisiblePublisher
            .sink { isVisible in
                isViewVisible = isVisible
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.onViewDisappeared()
        wait(for: [exp], timeout: 0.1)

        XCTAssertFalse(isViewVisible, "Expect view is not visible.")
        XCTAssertNil(sut.albumLoadingTask, "Expect to deallocate albumLoadingTask, but initialized instead.")
    }
    
    func testOnViewAppearedDisappeared_whenCalled_subscribeAndCancelLoadAlbumTasks() async throws {
        let sut = albumListViewModel()
        var isViewVisible = false
        let exp = expectation(description: "Wait for subscription emitted value")
        exp.expectedFulfillmentCount = 2
        sut.viewIsVisiblePublisher
            .sink { isVisible in
                isViewVisible = isVisible
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.onViewAppeared()
        await sut.albumLoadingTask?.value
        
        XCTAssertTrue(isViewVisible, "Expect view is visible.")
        XCTAssertNotNil(sut.albumLoadingTask, "Expect to initialize albumLoadingTask, but not initialized instead.")
        
        sut.onViewDisappeared()
        await sut.albumLoadingTask?.value
        await fulfillment(of: [exp], timeout: 0.1)
        
        XCTAssertFalse(isViewVisible, "Expect view is not visible.")
        let albumLoadingTask = try XCTUnwrap(sut.albumLoadingTask)
        XCTAssertTrue(albumLoadingTask.isCancelled, "Expect to cancel albumLoadingTask, but not cancelled instead.")
    }
    
    // MARK: - Helpers
    
    private func alertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                   placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                   affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                   message: nil)
    }
    
    private func albumListViewModel(
        usecase: some AlbumListUseCaseProtocol = MockAlbumListUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        shareAlbumUseCase: some ShareAlbumUseCaseProtocol = MockShareAlbumUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        photoAlbumContainerViewModel: PhotoAlbumContainerViewModel? = nil
    ) -> AlbumListViewModel {
        AlbumListViewModel(
            usecase: usecase,
            albumModificationUseCase: albumModificationUseCase,
            shareAlbumUseCase: shareAlbumUseCase,
            tracker: tracker,
            alertViewModel: alertViewModel(),
            photoAlbumContainerViewModel: photoAlbumContainerViewModel
        )
    }
}

extension PhotoAlbumContainerViewModel {
    convenience init() {
        self.init(tracker: MockTracker())
    }
}
