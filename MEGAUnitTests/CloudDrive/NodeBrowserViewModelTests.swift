import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import Search
import SearchMock
import XCTest

struct MockMEGANotificationUseCaseProtocol: MEGANotificationUseCaseProtocol {
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? { nil }
    
    func incomingContactRequest() -> [ContactRequestEntity] { [] }
    
    func observeUserAlerts(with callback: @escaping () -> Void) { }
    
    func observeUserContactRequests(with callback: @escaping () -> Void) { }
}

struct MockMEGAAvatarUseCaseProtocol: MEGAAvatarUseCaseProtocol {
    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void) {}
    
    func getCachedAvatarImage() -> UIImage? { nil }
    
    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void) { }
}

struct MockMEGAAvatarGeneratingUseCaseProtocol: MEGAAvatarGeneratingUseCaseProtocol {
    func avatarName() -> String? { nil }
    
    func avatarBackgroundColorHex() -> String? { nil }
}

class NodeBrowserViewModelTests: XCTestCase {
    
    class Harness {
        
        static let titleBuilderProvidedValue = "CD title"
        
        let sut: NodeBrowserViewModel
        
        init(node: NodeEntity) {
            let nodeSource = NodeSource.node { node }
            let expectedNodes = [
                node
            ]
            let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
            let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(
                nodeUpdates: AnyPublisher(nodeUpdatesPublisher),
                nodes: expectedNodes,
                shouldReload: true
            )
            
            sut = NodeBrowserViewModel(
                searchResultsViewModel: .init(
                    resultsProvider: MockSearchResultsProviding(),
                    bridge: SearchBridge(
                        selection: { _ in },
                        context: { _, _ in },
                        resignKeyboard: {},
                        chipTapped: { _, _ in }
                    ),
                    config: .testConfig,
                    layout: .list,
                    showLoadingPlaceholderDelay: 0,
                    searchInputDebounceDelay: 0,
                    keyboardVisibilityHandler: MockKeyboardVisibilityHandler()
                ),
                mediaDiscoveryViewModel: .init(
                    contentMode: .library,
                    parentNodeProvider: { node },
                    sortOrder: .nameAscending,
                    isAutomaticallyShown: false,
                    delegate: MockMediaDiscoveryContentDelegate(),
                    analyticsUseCase: MockMediaDiscoveryAnalyticsUseCase(),
                    mediaDiscoveryUseCase: mediaDiscoveryUseCase
                ),
                warningViewModel: nil, 
                upgradeEncouragementViewModel: nil,
                config: .default,
                nodeSource: nodeSource,
                avatarViewModel: MyAvatarViewModel(
                    megaNotificationUseCase: MockMEGANotificationUseCaseProtocol(),
                    megaAvatarUseCase: MockMEGAAvatarUseCaseProtocol(),
                    megaAvatarGeneratingUseCase: MockMEGAAvatarGeneratingUseCaseProtocol()
                ), 
                storageFullAlertViewModel: .init(router: MockStorageFullAlertViewRouting()),
                hasOnlyMediaNodesChecker: { false },
                titleBuilder: { _, _ in Self.titleBuilderProvidedValue },
                onOpenUserProfile: {},
                onUpdateSearchBarVisibility: { _ in },
                onBack: {}, 
                onEditingChanged: { _ in }
            )
        }
    }
    
    func testRefreshTitle_readUsesTitleBuild_toSetTitle() {
        let harness = Harness(node: .rootNode)
        harness.sut.refreshTitle()
        XCTAssertEqual(harness.sut.title, Harness.titleBuilderProvidedValue)
    }
}

extension NodeEntity {
    static var rootNode: NodeEntity {
        NodeEntity(name: "Cloud Drive", handle: 1)
    }
}
