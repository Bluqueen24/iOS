@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class GetLinkAlbumInfoCellViewModelTests: XCTestCase {

    func testDispatch_onViewReadyWithAlbumCover_shouldSetLabelsAndUpdateThumbnail() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, coverNode: NodeEntity(handle: 50), count: albumCount, type: .user)
        let sut = GetLinkAlbumInfoCellViewModel(album: album,
                                                thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: localURL, type: .thumbnail))))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setThumbnail(path: localURL.path)
        ])
    }
    
    func testDispatch_onViewReadyWithErrorAlbumCover_shouldSetLabelsAndSetPlaceholderThumbnail() throws {
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, coverNode: NodeEntity(handle: 50), count: albumCount, type: .user)
        let sut = GetLinkAlbumInfoCellViewModel(album: album,
                                                thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .failure(GenericErrorEntity())))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setPlaceholderThumbnail
        ])
    }
    
    func testDispatch_onViewReadyWithOutAlbumCover_shouldOnlySetLabels() throws {
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, count: albumCount, type: .user)
        let sut = GetLinkAlbumInfoCellViewModel(album: album,
                                                thumbnailUseCase: MockThumbnailUseCase())
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setPlaceholderThumbnail
        ])
    }
}
