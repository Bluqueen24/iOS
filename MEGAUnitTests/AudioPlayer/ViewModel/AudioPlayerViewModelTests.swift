@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASDKRepoMock
import XCTest

final class AudioPlayerViewModelTests: XCTestCase {
    
    func testPlaybackActions() {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        
        test(viewModel: onlineSUT, action: .onViewDidLoad, expectedCommands: [.showLoading(true),
                                                                              .configureFileLinkPlayer(title: "Track 5", subtitle: Strings.Localizable.fileLink),
                                                                              .updateShuffle(status: playerHandler.isShuffleEnabled()),
                                                                              .updateSpeed(mode: .normal)], timeout: 0.5)
        
        test(viewModel: onlineSUT, action: .updateCurrentTime(percentage: 0.2), expectedCommands: [])
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .progressDragEventBegan, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventBeganCalledTimes, 1)
        
        test(viewModel: onlineSUT, action: .progressDragEventEnded, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventEndedCalledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onShuffle(active: true), expectedCommands: [])
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onGoBackward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onPrevious, expectedCommands: [])
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onNext, expectedCommands: [])
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onGoForward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .loop)])
        XCTAssertEqual(playerHandler.onRepeatAll_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)])
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)])
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .deinit, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
        
        test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
        
        test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    func testRouterActions() {
        let router = MockAudioPlayerViewRouter()
        let (onlineSUT, _, _, _) = makeOnlineSUT(router: router)
        let (offlineSUT, _) = makeOfflineSUT(router: router)
        
        test(viewModel: onlineSUT, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .showPlaylist, expectedCommands: [])
        XCTAssertEqual(router.goToPlaylist_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
        
        test(viewModel: offlineSUT, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 2)
        
        test(viewModel: onlineSUT, action: .`import`, expectedCommands: [])
        XCTAssertEqual(router.importNode_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .share(sender: nil), expectedCommands: [])
        XCTAssertEqual(router.share_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .sendToChat, expectedCommands: [])
        XCTAssertEqual(router.sendToContact_calledTimes, 1)
        
        test(viewModel: onlineSUT, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [])
        XCTAssertEqual(router.showAction_calledTimes, 1)
    }
    
    func testOnReceiveAudioPlayerActions_shouldInvokeCorrectCommands() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        playbackUseCase._status = .startFromBeginning
        
        assert(
            onlineSUT,
            when: { viewModel in
                viewModel.audioDidStartPlayingItem(testItem)
            },
            shouldInvokeCommands: []
        )
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldDisplayDialog_andPausePlayer_whenAppIsActive() {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { true }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)
        
        assert(
            onlineSUT,
            when: { viewModel in
                viewModel.audioDidStartPlayingItem(testItem)
            },
            shouldInvokeCommands: [
                .displayPlaybackContinuationDialog(
                    fileName: testItem.name,
                    playbackTime: 1234.0
                )
            ]
        )
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldNotDisplayDialog_whenAppIsNotActive() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)
        
        assert(
            onlineSUT,
            when: { viewModel in
                viewModel.audioDidStartPlayingItem(testItem)
            },
            shouldInvokeCommands: []
        )
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldResumePlayback_whenAppIsNotActive() {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)
        
        onlineSUT.audioDidStartPlayingItem(testItem)
        
        XCTAssertEqual(playerHandler.pause_calledTimes, 0)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [1234.0])
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
    }
    
    func testAudioPlaybackContinuation_resumeSession() {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        playbackUseCase._status = .resumeSession(playbackTime: 1234.0)
        
        onlineSUT.audioDidStartPlayingItem(testItem)
        
        XCTAssertEqual(
            playerHandler.playerResumePlayback_Calls,
            [1234.0]
        )
    }
    
    func testSelectPlaybackContinuationDialog_shouldSetPreference() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: 1234.0))
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
        
        onlineSUT.dispatch(.onSelectRestartPlaybackContinuationDialog)
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession, .restartFromBeginning]
        )
    }
    
    func testViewDidLoad_whenViewDidLoadAfterDeinit_shouldProperlyPrepareCleanPlayerWithSingleTrack() throws {
        let firstAudioNode = MockNode(handle: 1, name: "first-audio", nodeType: .file)
        let latestAudioNode = MockNode(handle: 2, name: "latest-audio", nodeType: .file)
        let (firstSUT, _, firstPlayerHandler, _) = simulateUserViewDidLoadWithNewInstane(audioNode: firstAudioNode)
        
        _ = try XCTUnwrap(firstPlayerHandler.currentPlayer())
        
        firstSUT.dispatch(.deinit)
        XCTAssertNotNil(firstPlayerHandler.currentPlayer())
        
        let (differentSUT, _, differentPlayerHandler, _) = simulateUserViewDidLoadWithNewInstane(audioNode: latestAudioNode)
        
        XCTAssertEqual(differentPlayerHandler.setCurrent_callTimes, 0)
        try assertThatCleanPlayerStateForReuse(on: differentPlayerHandler, sut: differentSUT)
        XCTAssertTrue(differentSUT.isSingleTrackPlayer)
        differentSUT.invokeCommand = {
            XCTAssertEqual($0, .configureDefaultPlayer)
            XCTAssertEqual($0, .shuffleAction(enabled: false))
            XCTAssertEqual($0, .goToPlaylistAction(enabled: false))
            XCTAssertEqual($0, .nextTrackAction(enabled: false))
        }
    }
    
    // MARK: - Helpers
    
    private func makeOnlineSUT(router: MockAudioPlayerViewRouter = MockAudioPlayerViewRouter()) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler()
        let (sut, playbackUseCase) = makeSUT(
            configEntity: AudioPlayerConfigEntity(
                node: MEGANode(),
                isFolderLink: false,
                fileLink: "",
                playerHandler: playerHandler
            ),
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            router: router
        )
        return (sut, playbackUseCase, playerHandler, router)
    }
    
    private func makeOfflineSUT(router: MockAudioPlayerViewRouter = MockAudioPlayerViewRouter()) -> (sut: AudioPlayerViewModel, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler()
        let (sut, _) = makeSUT(
            configEntity: AudioPlayerConfigEntity(
                fileLink: "file_path",
                playerHandler: playerHandler
            ),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            router: router
        )
        return (sut, router)
    }
    
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        nodeInfoUseCase: (any NodeInfoUseCaseProtocol)? = nil,
        streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)? = nil,
        offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)? = nil,
        router: MockAudioPlayerViewRouter
    ) -> (sut: AudioPlayerViewModel, playbackContinuationUseCase: MockPlaybackContinuationUseCase) {
        let mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let sut = AudioPlayerViewModel(
            configEntity: configEntity,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: offlineInfoUseCase,
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            dispatchQueue: MockDispatchQueue()
        )
        return (sut, mockPlaybackContinuationUseCase)
    }
    
    private func simulateUserViewDidLoadWithNewInstane(audioNode: MockNode) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let router = MockAudioPlayerViewRouter()
        let configEntity = audioPlayerConfigEntity(node: audioNode)
        let (sut, playbackUseCase) = makeSUT(
            configEntity: configEntity,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            router: router
        )
        sut.dispatch(.onViewDidLoad)
        return (sut, playbackUseCase, configEntity.playerHandler as! MockAudioPlayerHandler, router)
    }
    
    private func assert(
        _ viewModel: AudioPlayerViewModel,
        when action: (AudioPlayerViewModel) -> Void,
        shouldInvokeCommands expectedCommands: [AudioPlayerViewModel.Command],
        line: UInt = #line
    ) {
        var invokedCommands =  [AudioPlayerViewModel.Command]()
        viewModel.invokeCommand = { invokedCommands.append($0) }
        
        action(viewModel)
        
        XCTAssertEqual(invokedCommands, expectedCommands, line: line)
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
    private func audioPlayerConfigEntity(node: MockNode, isFolderLink: Bool = false, fileLink: String? = nil) -> AudioPlayerConfigEntity {
        let playerHandler = MockAudioPlayerHandler()
        return AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            playerHandler: playerHandler
        )
    }
    
    private func assertThatCleanPlayerStateForReuse(on playerHandler: MockAudioPlayerHandler, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) throws {
        let player = try XCTUnwrap(playerHandler.currentPlayer(), file: file, line: line)
        assertThatRemovePreviousQueuedTrackInPlayer(on: player, file: file, line: line)
        assertThatRefreshPlayerListener(on: player, sut: sut, file: file, line: line)
    }
    
    private func assertThatRemovePreviousQueuedTrackInPlayer(on player: AudioPlayer, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(player.queuePlayer, file: file, line: line)
        XCTAssertTrue(player.tracks.isEmpty, file: file, line: line)
    }
    
    private func assertThatRefreshPlayerListener(on player: AudioPlayer, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(player.listenerManager.listeners.isEmpty, file: file, line: line)
        XCTAssertTrue(player.listenerManager.listeners.notContains(where: { $0 as! AnyHashable == sut as! AnyHashable }), file: file, line: line)
    }
}
