import Foundation
import MEGADomain

public struct MockDownloadFileRepository: DownloadFileRepositoryProtocol {
    
    public static let newRepo = MockDownloadFileRepository()
    
    private let completionResult: Result<TransferEntity, TransferErrorEntity>
    private let error: TransferErrorEntity
    private let transferEntity: TransferEntity?
    
    public init(completionResult: Result<TransferEntity, TransferErrorEntity> = .failure(.generic),
                error: TransferErrorEntity = .generic,
                transferEntity: TransferEntity? = nil) {
        self.completionResult = completionResult
        self.error = error
        self.transferEntity = transferEntity
    }
    
    public func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    public func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?) async throws -> TransferEntity {
        try await withCheckedThrowingContinuation { continuation in continuation.resume(with: completionResult) }
    }

    public func downloadChat(nodeHandle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    public func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    public func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    public func downloadChatFile(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    public func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, to url: URL, metaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    public func cancelDownloadTransfers() { }
}
