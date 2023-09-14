@testable import MEGA
import MEGADomain
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerViewRouterTests: XCTestCase {
    
    func testBuild_whenNodeIsFolderLink_configCorrectDelegate() {
        let (sut, _, _, _, _, _) = makeSUT(nodeOriginType: .folderLink)
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on: sut)
    }
    
    func testBuild_whenNodeIsFileLink_configCorrectDelegate() {
        let (sut, _, _, _, _, _) = makeSUT(nodeOriginType: .fileLink, fileLink: anyFileLink())
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on: sut)
    }
    
    func testBuild_whenNodeIsFromChat_configCorrectDelegate() {
        let expectedChatId = anyHandleEntity()
        let expectedMessageId = anyHandleEntity()
        let (sut, _, _, _, _, _) = makeSUT(nodeOriginType: .chat, messageId: expectedMessageId, chatId: expectedChatId)
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromChat(on: sut, expectedChatId, expectedMessageId)
    }
    
    func testStart_presentBuildedView() {
        let (sut, presenter, _, _, _, _) = makeSUT()
        
        sut.start()
        
        XCTAssertEqual(presenter.presentCallCount, 1)
    }
    
    func testShowMiniPlayer_withNode_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(node: MockNode(handle: 1), shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    func testShowMiniPlayer_withouthNode_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(node: nil, shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    func testShowMiniPlayer_withFile_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(file: "any-file", shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    func testGoToPlaylist_whenCalled_startsPlaylistRouter() {
        let (sut, _, _, _, audioPlaylistViewRouter, _) = makeSUT()
        
        sut.goToPlaylist()
        
        XCTAssertEqual(audioPlaylistViewRouter.start_calledTimes, 1)
    }
    
    func testDismiss_whenCalled_dismissView() {
        let (sut, _, _, _, _, audioPlayerViewController) = makeSUT(audioPlayerViewController: MockViewController())
        
        sut.dismiss()
        
        XCTAssertEqual(audioPlayerViewController.dismissCallCount, 1)
    }
    
    func testShowAction_whenCalled_presentNodeActionView() {
        let (sut, _, _, _, _, audioPlayerViewController) = makeSUT(audioPlayerViewController: MockViewController())
        
        sut.showAction(for: MockNode(handle: 1), sender: "any-sender")
        
        XCTAssertEqual(audioPlayerViewController.presentCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        nodeOriginType originType: AudioPlayerConfigEntity.NodeOriginType = .folderLink,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        audioPlayerViewController: MockViewController = MockViewController(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewRouter, presenter: MockViewController, configEntity: AudioPlayerConfigEntity, mockPlayerHandler: MockAudioPlayerHandler, audioPlaylistViewRouter: MockAudioPlaylistViewRouter, baseViewController: MockViewController) {
        let currentContextViewController = MockViewController()
        let audioPlaylistViewRouter = MockAudioPlaylistViewRouter()
        let (configEntity, mockPlayerHandler) = audioPlayerConfigEntity(
            from: originType,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles
        )
        let sut = AudioPlayerViewRouter(
            configEntity: configEntity,
            presenter: currentContextViewController,
            audioPlaylistViewRouter: audioPlaylistViewRouter
        )
        sut.baseViewController = audioPlayerViewController
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, currentContextViewController, configEntity, mockPlayerHandler, audioPlaylistViewRouter, audioPlayerViewController)
    }
    
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertTrue(sut.nodeActionViewControllerDelegate?.isNodeFromFolderLink == true, file: file, line: line)
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, .invalid, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, .invalid, file: file, line: line)
    }
    
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, nil, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, nil, file: file, line: line)
    }
    
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromChat(on sut: AudioPlayerViewRouter, _ expectedMessageId: HandleEntity, _ expectedChatId: HandleEntity, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, expectedMessageId, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, expectedChatId, file: file, line: line)
        XCTAssertTrue(sut.nodeActionViewControllerDelegate?.isNodeFromFolderLink == false, file: file, line: line)
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
    }
    
    private func audioPlayerConfigEntity(
        from originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        playerHandler: MockAudioPlayerHandler = MockAudioPlayerHandler()
    ) -> (configEntity: AudioPlayerConfigEntity, playerHandler: MockAudioPlayerHandler) {
        let node = MockNode(handle: .max)
        
        switch originType {
        case .folderLink:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .fileLink:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .chat:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .unknown:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        }
    }
    
    private func anyFileLink() -> String {
        anyURL().absoluteString
    }
    
    private func anyURL() -> URL {
        URL(string: "https://some-file-link.com")!
    }
    
    private func anyHandleEntity() -> HandleEntity {
        .max
    }
    
}

private class MockViewController: UIViewController {
    private(set) var presentCallCount = 0
    private(set) var dismissCallCount = 0
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCallCount += 1
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCallCount += 1
    }
}
