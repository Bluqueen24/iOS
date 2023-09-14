import MEGASdk
import MEGASDKRepo

public final class MockNode: MEGANode {
    private let nodeType: MEGANodeType
    private let nodeName: String
    private let nodeParentHandle: MEGAHandle
    private let nodeHandle: MEGAHandle
    private let changeType: MEGANodeChangeType
    private var nodeModificationTime: Date?
    private let _hasThumbnail: Bool
    private let isNodeDecrypted: Bool
    private let isNodeExported: Bool
    private let videoDuration: Int
    private let _label: MEGANodeLabel
    private let _isFavourite: Bool
    private let _fingerprint: String
    private let _hasPreview: Bool
    let nodePath: String?
    
    public init(handle: MEGAHandle,
                name: String = "",
                nodeType: MEGANodeType = .file,
                parentHandle: MEGAHandle = .invalidHandle,
                changeType: MEGANodeChangeType = .new,
                modificationTime: Date? = nil,
                hasThumbnail: Bool = false,
                nodePath: String? = nil,
                isNodeDecrypted: Bool = false,
                isNodeExported: Bool = false,
                duration: Int = 0,
                label: MEGANodeLabel = .unknown,
                isFavourite: Bool = false,
                fingerprint: String = "",
                hasPreview: Bool = false
    ) {
        nodeHandle = handle
        nodeName = name
        self.nodeType = nodeType
        nodeParentHandle = parentHandle
        self.changeType = changeType
        nodeModificationTime = modificationTime
        _hasThumbnail = hasThumbnail
        self.nodePath = nodePath
        self.isNodeDecrypted = isNodeDecrypted
        self.isNodeExported = isNodeExported
        self.videoDuration = duration
        _label = label
        _isFavourite = isFavourite
        self._fingerprint = fingerprint
        _hasPreview = hasPreview
        super.init()
    }
    
    public override var handle: MEGAHandle { nodeHandle }
    
    public override var type: MEGANodeType { nodeType }
    
    public override var duration: Int { videoDuration }
    
    public override func getChanges() -> MEGANodeChangeType { changeType }
    
    public override func hasChangedType(_ changeType: MEGANodeChangeType) -> Bool {
        self.changeType.rawValue & changeType.rawValue > 0
    }
    
    public override func isFile() -> Bool { nodeType == .file }
    
    public override func isFolder() -> Bool { nodeType == .folder }
    
    public override var name: String! { nodeName }
    
    public override var parentHandle: MEGAHandle { nodeParentHandle }
    
    public override var modificationTime: Date? { nodeModificationTime }
    
    public override func hasThumbnail() -> Bool { _hasThumbnail }
    
    public override func isExported() -> Bool { isNodeExported }
        
    public override var label: MEGANodeLabel { _label }
    
    public override var isFavourite: Bool { _isFavourite }
    
    public override var fingerprint: String? { _fingerprint }
    
    public override func hasPreview() -> Bool { _hasPreview }

    public override var base64Handle: String? { String(handle) }
}
