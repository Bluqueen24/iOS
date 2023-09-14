import MEGASdk
import MEGASDKRepo

public final class MockRequest: MEGARequest {
    private let handle: MEGAHandle
    private let _set: MEGASet?
    private let _text: String?
    private let _parentHandle: UInt64
    private let _elementsInSet: [MEGASetElement]
    private let _number: NSNumber
    private let _link: String?
    private let _flag: Bool
    private let _publicNode: MEGANode?
    private let _backupInfoList: [MEGABackupInfo]
    private let stringDict: [String: String]
    private let _file: String?
    private let _accountDetails: MEGAAccountDetails?
    private let _numDetails: Int
    
    public init(handle: MEGAHandle,
                set: MEGASet? = nil,
                text: String? = nil,
                parentHandle: MEGAHandle = .invalidHandle,
                elementInSet: [MEGASetElement] = [],
                number: NSNumber = 0,
                link: String? = nil,
                flag: Bool = false,
                publicNode: MEGANode? = nil,
                backupInfoList: [MEGABackupInfo] = [],
                stringDict: [String: String] = [:],
                file: String? = nil,
                accountDetails: MEGAAccountDetails? = nil,
                numDetails: Int = 0) {
        self.handle = handle
        _set = set
        _text = text
        _parentHandle = parentHandle
        _elementsInSet = elementInSet
        _number = number
        _link = link
        _flag = flag
        _publicNode = publicNode
        _backupInfoList = backupInfoList
        self.stringDict = stringDict
        _file = file
        _accountDetails = accountDetails
        _numDetails = numDetails
        super.init()
    }
    
    public override var nodeHandle: MEGAHandle { handle }
    public override var set: MEGASet? { _set }
    public override var text: String? { _text }
    public override var parentHandle: UInt64 { _parentHandle }
    public override var elementsInSet: [MEGASetElement] { _elementsInSet }
    public override var number: NSNumber { _number }
    public override var link: String? { _link }
    public override var flag: Bool { _flag }
    public override var publicNode: MEGANode? { _publicNode }
    public override var backupInfoList: [MEGABackupInfo] { _backupInfoList }
    public override var megaStringDictionary: [String: String] { stringDict }
    public override var file: String? { _file }
    public override var megaAccountDetails: MEGAAccountDetails? { _accountDetails }
    public override var numDetails: Int { _numDetails }
}
