import Combine

public protocol AlbumContentModificationUseCaseProtocol {
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
    func rename(album id: HandleEntity, with newName: String) async throws -> String
    func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity
    func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity
}

public final class AlbumContentModificationUseCase: AlbumContentModificationUseCaseProtocol {
    private let userAlbumRepo: UserAlbumRepositoryProtocol

    public init(userAlbumRepo: UserAlbumRepositoryProtocol) {
        self.userAlbumRepo = userAlbumRepo
    }
    
    // MARK: Protocols
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepo.addPhotosToAlbum(by: id, nodes: nodes)
    }
    
    public func rename(album id: HandleEntity, with newName: String) async throws -> String {
        try await userAlbumRepo.updateAlbumName(newName, id)
    }
    
    public func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity {
        guard let albumPhotoId = albumPhoto.albumPhotoId else { throw AlbumPhotoErrorEntity.photoIdDoesNotExist }
        return try await userAlbumRepo.updateAlbumCover(for: id, elementId: albumPhotoId)
    }

    public func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity {
        let photoIds = photos.compactMap(\.albumPhotoId)
        guard photoIds.isNotEmpty else {
            return AlbumElementsResultEntity(success: 0, failure: 0)
        }
        return try await userAlbumRepo.deleteAlbumElements(albumId: albumId, elementIds: photoIds)
    }
}
