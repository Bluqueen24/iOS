
protocol DownloadLinkRouterProtocol {
    func downloadFileLink()
    func downloadFolderLinkNodes()
    func showOnboarding()
}

final class DownloadLinkViewModel {
    private let router: DownloadLinkRouterProtocol
    private let authUseCase: AuthUseCaseProtocol
    private let reachabilityUseCase: ReachabilityUseCaseProtocol
    
    private let link: URL?
    private let isFolderLink: Bool
    private let nodes: [NodeEntity]?

    init(router: DownloadLinkRouterProtocol,
         authUseCase: AuthUseCaseProtocol,
         reachabilityUseCase: ReachabilityUseCaseProtocol,
         link: URL,
         isFolderLink: Bool) {
        self.router = router
        self.authUseCase = authUseCase
        self.reachabilityUseCase = reachabilityUseCase
        self.link = link
        self.nodes = nil
        self.isFolderLink = isFolderLink
    }
    
    init(router: DownloadLinkRouterProtocol,
         authUseCase: AuthUseCaseProtocol,
         reachabilityUseCase: ReachabilityUseCaseProtocol,
         nodes: [NodeEntity],
         isFolderLink: Bool) {
        self.router = router
        self.authUseCase = authUseCase
        self.reachabilityUseCase = reachabilityUseCase
        self.isFolderLink = isFolderLink
        self.link = nil
        self.nodes = nodes
    }
    
    func checkIfLinkCanBeDownloaded() {
        if reachabilityUseCase.isReachable() {
            if authUseCase.sessionId() != nil {
                if isFolderLink {
                    router.downloadFolderLinkNodes()
                } else {
                    router.downloadFileLink()
                }
            } else {
                if isFolderLink {
                    guard let nodes = nodes else {
                        return
                    }
                    MEGALinkManager.selectedOption = .downloadFolderOrNodes
                    MEGALinkManager.nodesFromLinkToDownloadAfterLogin(nodes: nodes)
                } else {
                    guard let link = link else {
                        return
                    }
                    MEGALinkManager.selectedOption = .downloadNode
                    MEGALinkManager.linkSavedString = link.absoluteString
                }
                
                router.showOnboarding()
            }
        }
    }
}
