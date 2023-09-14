import MEGASdk
import MEGASDKRepo

public final class MockSdk: MEGASdk {
    private var nodes: [MEGANode]
    private let rubbishNodes: [MEGANode]
    private let syncDebrisNodes: [MEGANode]
    private let backupInfoList: [MEGABackupInfo]
    private let _deviceId: String?
    private let myContacts: MEGAUserList
    public var _myUser: MEGAUser?
    public var _isLoggedIn: Int
    public var _isMasterBusinessAccount: Bool
    public var _isContactVerificationWarningEnabled: Bool
    private let _bandwidthOverquotaDelay: Int64
    private let email: String?
    private let megaRootNode: MEGANode?
    private let rubbishBinNode: MEGANode?
    private let sets: [MEGASet]
    private let setElements: [MEGASetElement]
    private let megaSetElementCounts: [MEGAHandle: UInt]
    private let nodeList: MEGANodeList
    private let shareList: MEGAShareList
    private let isSharedFolderOwnerVerified: Bool
    private let sharedFolderOwner: MEGAUser?
    private let incomingNodes: MEGANodeList
    private let outgoingNodes: MEGANodeList
    private let publicLinkNodes: MEGANodeList
    private let createSupportTicketError: MEGAErrorType
    private let link: String?
    private let megaSetError: MEGAErrorType
    private let _incomingContactRequests: MEGAContactRequestList
    private let _userAlertList: MEGAUserAlertList
    private let _upgradeSecurity: (MEGASdk, any MEGARequestDelegate) -> Void
    private let _accountDetails: (MEGASdk, any MEGARequestDelegate) -> Void
    private let smsState: SMSState
    private let devices: [String: String]
    private let file: String?
    private let copiedNodeHandles: [MEGAHandle: MEGAHandle]
    private let abTestValues: [String: Int]
    private let requestResult: Result<MEGARequest, MEGAError>
    
    public private(set) var sendEvent_Calls = [(
        eventType: Int,
        message: String,
        addJourneyId: Bool,
        viewId: String?
    )]()
    
    public private(set) var nodeForHandleCallCount = 0
    
    public private(set) var messages = [Message]()
    
    public enum Message: Equatable {
        case publicNodeForMegaFileLink(String)
    }
    
    public var hasGlobalDelegate = false
    public var hasRequestDelegate = false
    public var hasTransferDelegate = false
    public var apiURL: String?
    public var disablepkp: Bool?
    public var shareAccessLevel: MEGAShareType = .accessUnknown
    public var stopPublicSetPreviewCalled = 0
    public var authorizeNodeCalled = 0
    
    public init(nodes: [MEGANode] = [],
                rubbishNodes: [MEGANode] = [],
                syncDebrisNodes: [MEGANode] = [],
                incomingNodes: MEGANodeList = MEGANodeList(),
                outgoingNodes: MEGANodeList = MEGANodeList(),
                publicLinkNodes: MEGANodeList = MEGANodeList(),
                backupInfoList: [MEGABackupInfo] = [],
                deviceId: String? = nil,
                myContacts: MEGAUserList = MEGAUserList(),
                myUser: MEGAUser? = nil,
                isLoggedIn: Int = 0,
                isMasterBusinessAccount: Bool = false,
                isContactVerificationWarningEnabled: Bool = false,
                bandwidthOverquotaDelay: Int64 = 0,
                smsState: SMSState = .notAllowed,
                myEmail: String? = nil,
                megaSets: [MEGASet] = [],
                megaSetElements: [MEGASetElement] = [],
                megaRootNode: MEGANode? = nil,
                rubbishBinNode: MEGANode? = nil,
                megaSetElementCounts: [MEGAHandle: UInt] = [:],
                nodeList: MEGANodeList = MEGANodeList(),
                shareList: MEGAShareList = MEGAShareList(),
                isSharedFolderOwnerVerified: Bool = false,
                sharedFolderOwner: MEGAUser? = nil,
                createSupportTicketError: MEGAErrorType = .apiOk,
                link: String? = nil,
                megaSetError: MEGAErrorType = .apiOk,
                incomingContactRequestList: MEGAContactRequestList = MEGAContactRequestList(),
                userAlertList: MEGAUserAlertList = MEGAUserAlertList(),
                upgradeSecurity: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
                accountDetails: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
                devices: [String: String] = [:],
                file: String? = nil,
                copiedNodeHandles: [MEGAHandle: MEGAHandle] = [:],
                abTestValues: [String: Int] = [:],
                requestResult: Result<MEGARequest, MEGAError> = .failure(MockError.failingError)
    ) {
        self.nodes = nodes
        self.rubbishNodes = rubbishNodes
        self.syncDebrisNodes = syncDebrisNodes
        self.backupInfoList = backupInfoList
        _deviceId = deviceId
        self.myContacts = myContacts
        _myUser = myUser
        _isLoggedIn = isLoggedIn
        _isMasterBusinessAccount = isMasterBusinessAccount
        _isContactVerificationWarningEnabled = isContactVerificationWarningEnabled
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        self.smsState = smsState
        email = myEmail
        sets = megaSets
        setElements = megaSetElements
        self.megaRootNode = megaRootNode
        self.rubbishBinNode = rubbishBinNode
        self.megaSetElementCounts = megaSetElementCounts
        self.nodeList = nodeList
        self.shareList = shareList
        self.isSharedFolderOwnerVerified = isSharedFolderOwnerVerified
        self.sharedFolderOwner = sharedFolderOwner
        self.incomingNodes = incomingNodes
        self.outgoingNodes = outgoingNodes
        self.publicLinkNodes = publicLinkNodes
        self.createSupportTicketError = createSupportTicketError
        self.link = link
        self.megaSetError = megaSetError
        self._incomingContactRequests = incomingContactRequestList
        _userAlertList = userAlertList
        _upgradeSecurity = upgradeSecurity
        _accountDetails = accountDetails
        self.devices = devices
        self.file = file
        self.copiedNodeHandles = copiedNodeHandles
        self.abTestValues = abTestValues
        self.requestResult = requestResult
        super.init()
    }
    
    public func setNodes(_ nodes: [MEGANode]) { self.nodes = nodes }
    
    public func setShareAccessLevel(_ shareAccessLevel: MEGAShareType) {
        self.shareAccessLevel = shareAccessLevel
    }
    
    public override var myUser: MEGAUser? { _myUser }
    
    public override var myEmail: String? { email }
    
    public override var totalNodes: UInt { UInt(nodes.count) }
    
    public override var bandwidthOverquotaDelay: Int64 { _bandwidthOverquotaDelay }

    public override var isContactVerificationWarningEnabled: Bool { _isContactVerificationWarningEnabled }
    
    public override func node(forHandle handle: MEGAHandle) -> MEGANode? {
        nodeForHandleCallCount += 1
        return nodes.first { $0.handle == handle }
    }
    
    public override func parentNode(for node: MEGANode) -> MEGANode? {
        nodes.first { $0.handle == node.parentHandle }
    }
    
    public override func isNode(inRubbish node: MEGANode) -> Bool {
        rubbishNodes.contains(node)
    }
    
    public override func children(forParent parent: MEGANode) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func children(forParent parent: MEGANode, order: Int) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func childNode(forParent parent: MEGANode, name: String, type: Int) -> MEGANode? {
        nodes.first(where: { $0.name == name && $0.type.rawValue == type })
    }
    
    public override func contacts() -> MEGAUserList { myContacts }
    
    public override func sendEvent(_ eventType: Int, message: String, addJourneyId: Bool, viewId: String?) {
        sendEvent_Calls.append((eventType, message, addJourneyId, viewId))
    }
    
    public override func add(_ delegate: any MEGAGlobalDelegate) {
        hasGlobalDelegate = true
    }
    
    public override func remove(_ delegate: any MEGAGlobalDelegate) {
        hasGlobalDelegate = false
    }
    
    public override func add(_ delegate: any MEGARequestDelegate) {
        hasRequestDelegate = true
    }
    
    public override func remove(_ delegate: any MEGARequestDelegate) {
        hasRequestDelegate = false
    }
    
    public override func add(_ delegate: any MEGATransferDelegate) {
        hasTransferDelegate = true
    }
    
    public override func remove(_ delegate: any MEGATransferDelegate) {
        hasTransferDelegate = false
    }
    
    public override func copy(_ node: MEGANode, newParent: MEGANode, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: copiedNodeHandles[node.handle] ?? .invalid)
        delegate.onRequestFinish?(self,
                                  request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override var rootNode: MEGANode? { megaRootNode }
    public override var rubbishNode: MEGANode? { rubbishBinNode }
    
    public override func nodeListSearch(for node: MEGANode, search searchString: String?, cancelToken: MEGACancelToken, recursive: Bool, orderType: MEGASortOrderType, nodeFormatType: MEGANodeFormatType, folderTargetType: MEGAFolderTargetType) -> MEGANodeList {
        MockNodeList(nodes: nodes)
    }
    
    public override func nodePath(for node: MEGANode) -> String? {
        guard let mockNode = node as? MockNode else { return nil }
        
        return mockNode.nodePath
    }
    
    public override func numberChildren(forParent parent: MEGANode?) -> Int {
        var numberChildren = 0
        for node in nodes where node.parentHandle == parent?.handle {
            numberChildren += 1
        }
        return numberChildren
    }
    
    // MARK: - Sets
    
    public override func megaSets() -> [MEGASet] {
        sets
    }
    
    public override func megaSetElements(bySid sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> [MEGASetElement] {
        setElements
    }
    
    public override func megaSetElementCount(_ sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> UInt {
        megaSetElementCounts[sid] ?? 0
    }
    
    public override func megaSetElement(bySid sid: MEGAHandle, eid: MEGAHandle) -> MEGASetElement? {
        setElements.first(where: { $0.handle == eid})
    }
    
    public override func createSet(_ name: String?, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, set: MockMEGASet(handle: 1, userId: 0, coverId: 1, name: name ?? ""))
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func updateSetName(_ sid: MEGAHandle, name: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, text: name)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func removeSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, parentHandle: sid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func createSetElement(_ sid: MEGAHandle, nodeId: MEGAHandle, name: String?, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func updateSetElement(_ sid: MEGAHandle, eid: MEGAHandle, name: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, text: name)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func updateSetElementOrder(_ sid: MEGAHandle, eid: MEGAHandle, order: Int64, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, number: NSNumber(value: order))
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func removeSetElement(_ sid: MEGAHandle, eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, parentHandle: .invalid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func putSetCover(_ sid: MEGAHandle, eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: eid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
    
    public override func exportSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, link: link)
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func publicLinkForExportedSet(bySid sid: MEGAHandle) -> String? {
        link
    }
    
    public override func disableExportSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        delegate.onRequestFinish?(self, request: MEGARequest(),
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func fetchPublicSet(_ publicSetLink: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, set: sets.first, elementInSet: setElements)
        
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func previewElementNode(_ eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, publicNode: nodes.first)
        
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func publicSetElementsInPreview() -> [MEGASetElement] {
        setElements
    }
    
    // MARK: - Share
    public override func contact(forEmail: String?) -> MEGAUser? {
        sharedFolderOwner
    }
    
    public override func areCredentialsVerified(of: MEGAUser) -> Bool {
        isSharedFolderOwnerVerified
    }
    
    public override func publicLinks(_ order: MEGASortOrderType) -> MEGANodeList {
        nodeList
    }
    
    public override func outShares(_ order: MEGASortOrderType) -> MEGAShareList {
        shareList
    }
    
    public override func openShareDialog(_ node: MEGANode, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle)
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func upgradeSecurity(with delegate: any MEGARequestDelegate) {
        _upgradeSecurity(self, delegate)
    }
    
    public override func nodeListSearchOnInShares(by searchString: String, cancelToken: MEGACancelToken, order orderType: MEGASortOrderType) -> MEGANodeList {
        filterNodeList(incomingNodes, by: searchString)
    }
    
    public override func nodeListSearchOnOutShares(by searchString: String, cancelToken: MEGACancelToken, order orderType: MEGASortOrderType) -> MEGANodeList {
        filterNodeList(outgoingNodes, by: searchString)
    }
    
    public override func nodeListSearchOnPublicLinks(by searchString: String, cancelToken: MEGACancelToken, order orderType: MEGASortOrderType) -> MEGANodeList {
        filterNodeList(publicLinkNodes, by: searchString)
    }
    
    private func filterNodeList(_ nodeList: MEGANodeList, by searchString: String) -> MEGANodeList {
        let nodeArray = nodeList.toNodeArray()
            .filter { $0.name?.contains(searchString) ?? false }
        
        return MockNodeList(nodes: nodeArray)
    }
    
    public override func disableExport(_ node: MEGANode, delegate: any MEGARequestDelegate) {
        nodes = nodes.compactMap { currentNode in
            if currentNode.handle == node.handle {
                return MockNode(handle: node.handle, isNodeExported: false)
            }
            return currentNode
        }
        
        let mockRequest = MockRequest(handle: 1)
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func accessLevel(for node: MEGANode) -> MEGAShareType {
        shareAccessLevel
    }
    
    public override func createSupportTicket(withMessage message: String, type: Int, delegate: any MEGARequestDelegate) {
        delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: MockError(errorType: createSupportTicketError))
    }
    
    // MARK: - Login Requests
    
    public override func isLoggedIn() -> Int { _isLoggedIn }
    
    public override func multiFactorAuthCheck(withEmail email: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, flag: true)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    // MARK: - File System Inspection
    
    public override func incomingContactRequests() -> MEGAContactRequestList {
        _incomingContactRequests
    }
    
    public override func userAlertList() -> MEGAUserAlertList {
        _userAlertList
    }
    
    // MARK: - Account Management
    
    public override var isMasterBusinessAccount: Bool { _isMasterBusinessAccount }
    
    public override func getAccountDetails(with delegate: any MEGARequestDelegate) {
        _accountDetails(self, delegate)
    }
    
    // MARK: - SMS
    
    public override func smsAllowedState() -> SMSState {
        smsState
    }
    
    // MARK: - Backups
    public override func getBackupInfo(_ delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, backupInfoList: backupInfoList)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func getUserAttributeType(_ type: MEGAUserAttribute, delegate: any MEGARequestDelegate) {
        var mockRequest: MockRequest?
        
        switch type {
        case .deviceNames:
            mockRequest = MockRequest(handle: 1, stringDict: devices)
        default: break
        }
        
        delegate.onRequestFinish?(self, request: mockRequest ?? MockRequest(handle: 1), error: MockError(errorType: megaSetError))
    }
    
    public override func deviceId() -> String? {
        _deviceId
    }

    public override func getThumbnailNode(_ node: MEGANode, destinationFilePath: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle, file: file)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func getPreviewNode(_ node: MEGANode, destinationFilePath: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle, file: file)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func stopPublicSetPreview() {
        stopPublicSetPreviewCalled += 1
    }
    
    public override func publicNode(forMegaFileLink megaFileLink: String, delegate: any MEGARequestDelegate) {
        messages.append(.publicNodeForMegaFileLink(megaFileLink))
    }
    
    // MARK: - A/B testing
    public override func getABTestValue(_ flag: String) -> Int {
        abTestValues[flag] ?? 0
    }
    
    public override func authorizeNode(_ node: MEGANode) -> MEGANode? {
        authorizeNodeCalled += 1
        return node
    }
    
    public override func startDownloadNode(_ node: MEGANode, localPath: String, fileName: String?, appData: String?, startFirst: Bool, cancelToken: MEGACancelToken?, collisionCheck: CollisionCheck, collisionResolution: CollisionResolution, delegate: any MEGATransferDelegate) {
        delegate.onTransferFinish?(
            self,
            transfer: MockTransfer(type: .download, nodeHandle: node.handle, parentHandle: node.parentHandle),
            error: MockError(errorType: .apiOk))
    }
    
    // MARK: - ADS
    
    public override func fetchAds(_ adFlags: AdsFlag, adUnits: MEGAStringList, publicHandle: MEGAHandle, delegate: any MEGARequestDelegate) {
        switch requestResult {
        case .success(let request):
            delegate.onRequestFinish?(self, request: request, error: MEGAError())
        case .failure(let error):
            delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: error)
        }
    }
    
    public override func queryAds(_ adFlags: AdsFlag, publicHandle: MEGAHandle, delegate: any MEGARequestDelegate) {
        switch requestResult {
        case .success(let request):
            delegate.onRequestFinish?(self, request: request, error: MEGAError())
        case .failure(let error):
            delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: error)
        }
    }
}

private extension MEGANodeList {
    func toNodeArray() -> [MEGANode] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap { node(at: $0) }
    }
}
