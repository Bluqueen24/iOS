import Combine
import MEGADomain

final class FilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    static var newRepo: FilesSearchRepository {
        FilesSearchRepository(sdk: MEGASdk.shared)
    }
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    private let updater: PassthroughSubject<[NodeEntity], Never>
    private let sdk: MEGASdk
    private var callback: (([NodeEntity]) -> Void)?
    private var cancelToken = MEGACancelToken()
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        
        updater = PassthroughSubject<[NodeEntity], Never>()
        nodeUpdatesPublisher = AnyPublisher(updater)
    }
    
    // MARK: - FilesSearchRepositoryProtocol
    
    func startMonitoringNodesUpdate(callback: (([NodeEntity]) -> Void)?) {
        self.callback = callback
        sdk.add(self)
    }
    
    func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
    
    func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(nil, true)
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           supportCancel: supportCancel,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(nodes, fail)
        }
    }
    
    func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation({ continuation in
            search(string: string,
                   parent: node,
                   supportCancel: supportCancel,
                   sortOrderType: sortOrderType,
                   formatType: formatType) {
                guard Task.isCancelled == false else { continuation.resume(throwing: FileSearchResultErrorEntity.cancelled); return }
                
                continuation.resume(with: $0)
            }
        })
    }
    
    func node(by handle: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    func cancelSearch() {
        guard searchOperationQueue.operationCount > 0 else { return }
        
        cancelToken.cancel()
        searchOperationQueue.cancelAllOperations()
    }
    
    // MARK: - Private
    
    private func search(string: String?,
                        parent node: NodeEntity?,
                        supportCancel: Bool,
                        sortOrderType: SortOrderEntity,
                        formatType: NodeFormatEntity,
                        completion: @escaping (Result<[NodeEntity], any Error>) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(.failure(NodeSearchResultErrorEntity.noDataAvailable))
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           supportCancel: supportCancel,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(fail ? .failure(NodeSearchResultErrorEntity.noDataAvailable) : .success(nodes ?? []))
        }
    }
    
    private func addSearchOperation(string: String?,
                                    parent: MEGANode,
                                    supportCancel: Bool,
                                    sortOrderType: SortOrderEntity,
                                    formatType: NodeFormatEntity,
                                    completion: @escaping ([MEGANode]?, Bool) -> Void) {
        cancelToken = MEGACancelToken()
        
        let searchOperation = SearchOperation(parentNode: parent,
                                              text: string ?? "",
                                              cancelToken: supportCancel ? cancelToken : MEGACancelToken(),
                                              sortOrderType: sortOrderType.toMEGASortOrderType(),
                                              nodeFormatType: formatType.toMEGANodeFormatType(),
                                              completion: completion)
        searchOperationQueue.addOperation(searchOperation)
    }
}

extension FilesSearchRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let callback else {
            updater.send(nodeList?.toNodeEntities() ?? [])
            return
        }
        
        callback(nodeList?.toNodeEntities() ?? [])
    }
}
