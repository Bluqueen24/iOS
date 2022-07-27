
import XCTest
@testable import MEGA

class DownloadLinkViewModelTests: XCTestCase {

    func testDownloadFileLinkUserLogged() {
        let router = MockDownloadLinkOrOnboardingRouter()
        let viewModel = DownloadLinkViewModel(router: router, authUseCase: MockAuthUseCase(loginSessionId: "mockSessionId", isUserLoggedIn: true), reachabilityUseCase: MockReachabilityUseCase(), link: URL(string: "fileLinkUrl")!, isFolderLink: false)
        viewModel.checkIfLinkCanBeDownloaded()
        XCTAssert(router.downloadFileLink_calledTimes == 1)
    }
    
    func testDownloadFolderLinkUserLogged() {
        let router = MockDownloadLinkOrOnboardingRouter()
        let viewModel = DownloadLinkViewModel(router: router, authUseCase: MockAuthUseCase(loginSessionId: "mockSessionId", isUserLoggedIn: true), reachabilityUseCase: MockReachabilityUseCase(), nodes: [NodeEntity()], isFolderLink: true)
        viewModel.checkIfLinkCanBeDownloaded()
        XCTAssert(router.downloadFolderLinkNodes_calledTimes == 1)
    }

    func testDownloadFileLinkUserNotLogged() {
        let router = MockDownloadLinkOrOnboardingRouter()
        let viewModel = DownloadLinkViewModel(router: router, authUseCase: MockAuthUseCase(isUserLoggedIn: false), reachabilityUseCase: MockReachabilityUseCase(), link: URL(string: "fileLinkUrl")!, isFolderLink: false)
        viewModel.checkIfLinkCanBeDownloaded()
        XCTAssert(router.showOnboarding_calledTimes == 1)
    }
    
    func testDownloadFolderLinkUserNotLogged() {
        let router = MockDownloadLinkOrOnboardingRouter()
        let viewModel = DownloadLinkViewModel(router: router, authUseCase: MockAuthUseCase(isUserLoggedIn: false), reachabilityUseCase: MockReachabilityUseCase(), nodes: [NodeEntity()], isFolderLink: true)
        viewModel.checkIfLinkCanBeDownloaded()
        XCTAssert(router.showOnboarding_calledTimes == 1)
    }
}

final class MockDownloadLinkOrOnboardingRouter: DownloadLinkRouterProtocol {
    var downloadFileLink_calledTimes = 0
    var downloadFolderLinkNodes_calledTimes = 0
    var showOnboarding_calledTimes = 0
    
    func downloadFileLink() {
        downloadFileLink_calledTimes = 1
    }
    
    func downloadFolderLinkNodes() {
        downloadFolderLinkNodes_calledTimes = 1
    }
    
    func showOnboarding() {
        showOnboarding_calledTimes = 1
    }
}
