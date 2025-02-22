import MEGADomain
import MEGASdk
import MEGASwift

public actor PhotosRepository: PhotosRepositoryProtocol {
    public static let sharedRepo = {
        let sdk = MEGASdk.sharedSdk
        return PhotosRepository(sdk: sdk,
                                photoLocalSource: PhotosInMemoryCache.shared,
                                nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk))
    }()
    
    private let sdk: MEGASdk
    private let photoLocalSource: any PhotoLocalSourceProtocol
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    
    private var searchAllPhotosTask: Task<[NodeEntity], Error>?
    private var monitorNodeUpdatesTask: Task<Void, Error>?
    private var photosUpdatedContinuations: [UUID: AsyncStream<[NodeEntity]>.Continuation] = [:]
    
    public var photosUpdated: AnyAsyncSequence<[NodeEntity]> {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        photosUpdatedContinuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.photoContinuationTerminated(id: id) }
        }
        return stream.eraseToAnyAsyncSequence()
    }
    
    public init(sdk: MEGASdk,
                photoLocalSource: some PhotoLocalSourceProtocol,
                nodeUpdatesProvider: some NodeUpdatesProviderProtocol) {
        self.sdk = sdk
        self.photoLocalSource = photoLocalSource
        self.nodeUpdatesProvider = nodeUpdatesProvider
        Task { await monitorNodeUpdates() }
    }
    
    deinit {
        searchAllPhotosTask?.cancel()
        monitorNodeUpdatesTask?.cancel()
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        let photosFromSource = await photoLocalSource.photos
        try Task.checkCancellation()
        if photosFromSource.isNotEmpty {
            return photosFromSource
        }
        return try await loadAllPhotos()
    }
    
    public func photo(forHandle handle: HandleEntity) async -> NodeEntity? {
        if let photoFromSource = await photoLocalSource.photo(forHandle: handle) {
            return photoFromSource
        }
        guard let photo = sdk.node(forHandle: handle)?.toNodeEntity() else {
            return nil
        }
        await photoLocalSource.setPhotos([photo])
        return photo
    }
    
    // MARK: Private
    
    private func loadAllPhotos() async throws -> [NodeEntity] {
        if let searchAllPhotosTask {
            return try await searchAllPhotosTask.value
        }
        let searchPhotosTask = Task<[NodeEntity], Error> {
            return try await searchAllPhotos()
        }
        self.searchAllPhotosTask = searchPhotosTask
        defer { self.searchAllPhotosTask = nil }
        
        return try await withTaskCancellationHandler {
            let photos = try await searchPhotosTask.value
            await photoLocalSource.setPhotos(photos)
            return photos
        } onCancel: {
            searchPhotosTask.cancel()
        }
    }
    
    private func searchAllPhotos() async throws -> [NodeEntity] {
        let photos = try await searchAllMedia(formatType: .photo)
        try Task.checkCancellation()
        let videos = try await searchAllMedia(formatType: .video)
        try Task.checkCancellation()
        return photos + videos
    }
    
    private func searchAllMedia(formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        let cancelToken = MEGACancelToken()
        
        return try await withTaskCancellationHandler {
            try await withAsyncThrowingValue { completion in
                guard let rootNode = sdk.rootNode else {
                    completion(.failure(NodeErrorEntity.nodeNotFound))
                    return
                }
                let nodeListFound = sdk.nodeListSearch(for: rootNode,
                                                       search: "",
                                                       cancelToken: cancelToken,
                                                       recursive: true,
                                                       orderType: .defaultDesc,
                                                       nodeFormatType: formatType.toMEGANodeFormatType(),
                                                       folderTargetType: .all)
                
                completion(.success(nodeListFound.toNodeEntities()))
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
    
    private func monitorNodeUpdates() {
        monitorNodeUpdatesTask = Task {
            for await nodeUpdates in nodeUpdatesProvider.nodeUpdates {
                guard !Task.isCancelled else {
                    terminatePhotoContinuations()
                    break
                }
                let updatedPhotos = nodeUpdates.filter(\.fileExtensionGroup.isVisualMedia)
                guard updatedPhotos.isNotEmpty else { continue }
                await updatePhotos(updatedPhotos)
                
                guard let allPhotos = try? await allPhotos(),
                      allPhotos.isNotEmpty else {
                    continue
                }
                yieldPhotosToContinuations(allPhotos)
            }
        }
    }
    
    private func updatePhotos(_ updatedPhotos: [NodeEntity]) async {
        let photosToStore = await withTaskGroup(of: NodeEntity?.self) { group in
            updatedPhotos.forEach { updatedPhoto in
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    
                    if !updatedPhoto.changeTypes.contains(.new) {
                        await photoLocalSource.removePhoto(forHandle: updatedPhoto.handle)
                    }
                    
                    guard let photo = sdk.node(forHandle: updatedPhoto.handle),
                          !sdk.isNode(inRubbish: photo) else {
                        return nil
                    }
                    return photo.toNodeEntity()
                }
            }
            return await group.reduce(into: [NodeEntity](), {
                if let updatedPhoto = $1 { $0.append(updatedPhoto) }
            })
        }
        
        guard photosToStore.isNotEmpty else { return }
        await photoLocalSource.setPhotos(photosToStore)
    }
    
    private func yieldPhotosToContinuations(_ photos: [NodeEntity]) {
        for continuation in photosUpdatedContinuations.values {
            continuation.yield(photos)
        }
    }
    
    private func photoContinuationTerminated(id: UUID) {
        photosUpdatedContinuations[id] = nil
    }
    
    private func terminatePhotoContinuations() {
        for continuation in photosUpdatedContinuations.values {
            continuation.finish()
        }
    }
}
