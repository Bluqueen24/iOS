import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import MEGASwift
import Search

/// abstraction into a search results
final class HomeSearchResultsProvider: SearchResultsProviding {
    
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    private var nodesUpdateListenerRepo: any NodesUpdateListenerProtocol
    private var transferListenerRepo: SDKTransferListenerRepository

    private let sdk: MEGASdk

    // We only initially fetch the node list when the user triggers search
    // Concrete nodes are then loaded one by one in the pagination
    private var nodeList: NodeListEntity?
    private var currentPage = 0
    private var totalPages = 0
    private var pageSize = 100
    private var loadMorePagesOffset = 20
    private var isLastPageReached = false
    private var availableChips: [SearchChipEntity]
    private let onSearchResultUpdated: (SearchResult) -> Void
    
    // The node from which we want start searching from,
    // root node can be nil in case when we start app in offline
    private let parentNodeProvider: () -> NodeEntity?
    private let mapper: SearchResultMapper
    
    init(
        parentNodeProvider: @escaping () -> NodeEntity?,
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol,
        nodesUpdateListenerRepo: any NodesUpdateListenerProtocol,
        transferListenerRepo: SDKTransferListenerRepository,
        allChips: [SearchChipEntity],
        sdk: MEGASdk,
        onSearchResultUpdated: @escaping (SearchResult) -> Void
    ) {
        self.parentNodeProvider = parentNodeProvider
        self.searchFileUseCase = searchFileUseCase
        self.nodeUseCase = nodeUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeRepository = nodeRepository
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        self.transferListenerRepo = transferListenerRepo
        self.availableChips = allChips
        self.sdk = sdk
        
        mapper = SearchResultMapper(
            sdk: sdk,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            mediaUseCase: mediaUseCase
        )

        self.onSearchResultUpdated = onSearchResultUpdated
        addNodesUpdateHandler()
        addTransferCompletedHandler()
    }
    
    func search(queryRequest: SearchQuery, lastItemIndex: Int? = nil) async throws -> SearchResultsEntity? {
        if let lastItemIndex {
            return try await loadMore(queryRequest: queryRequest, index: lastItemIndex)
        } else {
            return try await searchInitially(queryRequest: queryRequest)
        }
    }
    
    func currentResultIds() -> [Search.ResultId] {
        guard let nodeList else {
            return []
        }
        // need to cache this probably so that subsequent opens are fast for large datasets
        return nodeList.toNodeEntities().map { $0.id }
    }
    
    func searchInitially(queryRequest: SearchQuery) async throws -> SearchResultsEntity {
        // the requirement is to return children/contents of the
        // folder being searched when query is empty, no chips etc
        
        currentPage = 0
        isLastPageReached = false
        
        switch queryRequest {
        case .initial:
            return await childrenOfRoot()
        case .userSupplied(let query):
            if shouldShowRoot(for: query) {
                return await childrenOfRoot()
            } else {
                self.nodeList = try await fullSearch(with: query)
                return await fillResults(query: query)
            }
        }
    }
    
    func loadMore(queryRequest: SearchQuery, index: Int) async throws -> SearchResultsEntity? {
        let itemsInPage = (currentPage == 0 ? 1 : currentPage)*pageSize
        guard index >= itemsInPage - loadMorePagesOffset else { return nil }
        
        currentPage+=1
        
        switch queryRequest {
        case .initial:
            return await fillResults()
        case .userSupplied(let query):
            return await fillResults(query: query)
        }
    }
    
    private var parentNode: NodeEntity? {
        parentNodeProvider()
    }
    
    private func childrenOfRoot() async -> SearchResultsEntity {
        guard let parentNode else {
            return .empty
        }
        self.nodeList = await nodeRepository.children(of: parentNode)
        return await fillResults()
    }
    
    private var searchPath: SearchFileRootPath {
        guard 
            let parentNode,
            parentNode != nodeRepository.rootNode()
        else {
            return .root
        }
        return .specific(parentNode.handle)
    }
    
    private func fullSearch(with queryRequest: SearchQueryEntity) async throws -> NodeListEntity? {
        // SDK does not support empty query and MEGANodeFormatType.unknown
        assert(!(queryRequest.query == "" && queryRequest.chips == []))
        MEGALogInfo("[search] full search \(queryRequest.query)")

        return await withAsyncValue(in: { completion in
            searchFileUseCase.searchFiles(
                withFilter: queryRequest.searchFilter,
                recursive: true,
                sortOrder: .defaultAsc,
                searchPath: searchPath,
                completion: { nodeList in
                    completion(.success(nodeList))
                }
            )
        })
    }

    private func childrenFolders() async throws -> NodeListEntity? {
        guard let root = nodeRepository.rootNode() else { return nil }
        guard let nodeList = await nodeRepository.children(of: root) else { return nil }

        let nodes = nodeList.toNodeEntities().filter { $0.isFolder }

        return .init(nodesCount: nodes.count, nodeAt: { nodes[$0] })
    }

    private func shouldShowRoot(for queryRequest: SearchQueryEntity) -> Bool {
        if queryRequest == .initialRootQuery {
            return true
        }
        if queryRequest.query == "" && queryRequest.chips == [] {
            return true
        }
        return false
    }
    
    private func fillResults(query: SearchQueryEntity? = nil) async -> SearchResultsEntity {
        guard let nodeList, nodeList.nodesCount > 0, !isLastPageReached else {
            return .init(
                results: [],
                availableChips: availableChips,
                appliedChips: query != nil ? chipsFor(query: query!) : []
            )
        }
        
        let nodesCount = nodeList.nodesCount
        let previousPageStartIndex = (currentPage-1)*pageSize
        let currentPageStartIndex = currentPage*pageSize
        let nextPageFirstIndex = (currentPage+1)*pageSize
        
        isLastPageReached = nextPageFirstIndex > nodesCount
        
        let firstItemIndex = currentPageStartIndex > nodesCount ? previousPageStartIndex : currentPageStartIndex
        let lastItemIndex = isLastPageReached ? nodesCount : nextPageFirstIndex
        
        var results: [SearchResult] = []
        for i in firstItemIndex...lastItemIndex-1 {
            if let nodeAt = nodeList.nodeAt(i) {
                results.append(mapNodeToSearchResult(nodeAt))
            }
        }

        return .init(
            results: results,
            availableChips: availableChips,
            appliedChips: query != nil ? chipsFor(query: query!) : []
        )
    }
    
    private func chipsFor(query: SearchQueryEntity) -> [SearchChipEntity] {
        query.chips
    }
    
    private func mapNodeToSearchResult(_ node: NodeEntity) -> SearchResult {
        mapper.map(node: node)
    }
    
    private func addNodesUpdateHandler() {
        nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            // After update, the first node in nodeList is always the updated one
            guard let self, let node = nodes.first else { return }
            self.onSearchResultUpdated(self.mapNodeToSearchResult(node))
        }
    }

    private func addTransferCompletedHandler() {
        transferListenerRepo.endHandler = { [weak self] megaNode, isStreamingTransfer, transferType in
            guard let self else { return }

            let node = megaNode.toNodeEntity()

            guard nodeList?.toNodeEntities().contains(node) != nil,
                  !isStreamingTransfer,
                  transferType == .download else {
                return
            }

            self.onSearchResultUpdated(self.mapNodeToSearchResult(node))
        }
    }
}
