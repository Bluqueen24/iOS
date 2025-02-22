@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

class CloudDriveViewModelTests: XCTestCase {
    
    func testUpdateEditModeActive_changeActiveToTrueWhenCurrentlyActive_shouldInvokeOnlyOnce() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(true))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyNotActive_shouldInvokeNotInvoke() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(false))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyActive_shouldInvokeEnterAndExitCommands() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode, .exitSelectionMode])
    }
    
    func testShouldShowMediaDiscoveryAutomatically_containsNonMediaFiles_shouldReturnFalse() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testShouldShowMediaDiscoveryAutomatically_containsOnlyMediaFiles_shouldReturnTrue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testShouldShowMediaDiscoveryAutomatically_preferenceOff_shouldReturnFalse() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testHasMediaFiles_nodesContainVisualMediaFile_shouldReturnTrue() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.hasMediaFiles(nodes: nodes))
    }
    
    func testHasMediaFiles_nodesDoesNotContainVisualMediaFile_shouldReturnFalse() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.docx")])
        XCTAssertFalse(sut.hasMediaFiles(nodes: nodes))
    }
    
    func testSortOrder_whereViewModeIsMediaDiscovery_shouldReturnEitherNewestOrOldest() throws {
        
        let expectations: [(SortOrderEntity, SortOrderType)] = [
            (.defaultAsc, .newest),
            (.modificationAsc, .oldest),
            (.modificationDesc, .newest),
            (.favouriteDesc, .newest),
            (.favouriteAsc, .newest)
        ]
        
        expectations.forEach { (arrangement, expect) in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: arrangement))
            // Act
            let result = sut.sortOrder(for: .mediaDiscovery)
            XCTAssertEqual(result, expect, "Given SortOrderEntity \(arrangement)")
        }
    }
    
    func testSortOrder_whereViewModeIsList_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .list)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    func testSortOrder_whereViewModeIsThumbnail_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .thumbnail)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    func testSortOrder_whereViewModeIsPerFolder_shouldReturnMatchingSortOrder() throws {
        
        SortOrderEntity.allCases.forEach { sortOrder in
            // Arrange
            let sut = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: sortOrder))
            // Act
            let result = sut.sortOrder(for: .perFolder)
            // Assert
            XCTAssertEqual(result, sortOrder.toSortOrderType(), "Given SortOrderEntity \(sortOrder)")
        }
    }
    
    func testShouldShowConfirmationAlertForRemovedFiles() {
        let sut = makeSUT()
        
        let inputs: [(fileCount: Int, folderCount: Int)] = [
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1)
        ]
        
        let expected: [Bool] = [false, true, true, true]
        
        let outputs = inputs.map {
            sut.shouldShowConfirmationAlert(forRemovedFiles: $0.fileCount, andFolders: $0.folderCount)
        }
        
        XCTAssertEqual(outputs, expected)
    }

    func makeSUT(
        parentNode: MEGANode = MockNode(handle: 1),
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:]),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        file: StaticString = #file,
        line: UInt = #line
    ) -> CloudDriveViewModel {
        let sut = CloudDriveViewModel(
            parentNode: parentNode,
            shareUseCase: shareUseCase, 
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            preferenceUseCase: preferenceUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
