import Foundation
import MEGADomain
import MEGAL10n

struct PhotosFilterOptionKeys {
    static let cameraUploadTimeline = "cameraUploadTimeline"
}

enum PhotosFilterType: CaseIterable {
    case allMedia
    case images
    case videos
    
    var localization: String {
        var type = ""
        switch self {
        case .allMedia: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia
        case .images: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images
        case .videos: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos
        }
        return type
    }
}

extension PhotosFilterType {
    func toContentConsumptionMediaType() -> ContentConsumptionMediaType {
        switch self {
        case .allMedia: return .allMedia
        case .images: return .images
        case .videos: return .videos
        }
    }
    
    static func toFilterType(from contentConsumptionMediaType: ContentConsumptionMediaType) -> PhotosFilterType {
        switch contentConsumptionMediaType {
        case .allMedia: return .allMedia
        case .images: return .images
        case .videos: return .videos
        }
    }
}

enum PhotosFilterLocation: CaseIterable {
    case allLocations
    case cloudDrive
    case cameraUploads
    
    var localization: String {
        var location = ""
        switch self {
        case .allLocations: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.allLocations
        case .cloudDrive: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.cloudDrive
        case .cameraUploads: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.cameraUploads
        }
        return location
    }
}

extension PhotosFilterLocation {
    func toContentConsumptionMediaLocation() -> ContentConsumptionMediaLocation {
        switch self {
        case .allLocations: return .allLocations
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        }
    }
    
    static func toFilterLocation(from contentConsumptionMediaLocation: ContentConsumptionMediaLocation) -> PhotosFilterLocation {
        switch contentConsumptionMediaLocation {
        case .allLocations: return .allLocations
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        }
    }
}

struct PhotosFilterOptions: OptionSet {
    static let allMedia = PhotosFilterOptions(rawValue: 1)
    static let images = PhotosFilterOptions(rawValue: 1 << 1)
    static let videos = PhotosFilterOptions(rawValue: 1 << 2)
    
    static let allLocations = PhotosFilterOptions(rawValue: 1 << 3)
    static let cloudDrive = PhotosFilterOptions(rawValue: 1 << 4)
    static let cameraUploads = PhotosFilterOptions(rawValue: 1 << 5)
    
    let rawValue: Int8
}

extension PhotosFilterOptions {
    static var allImages: PhotosFilterOptions {
        return [.images, .allLocations]
    }
    
    static var allVideos: PhotosFilterOptions {
        return [.videos, .allLocations]
    }
    
    static var allVisualFiles: PhotosFilterOptions {
        return [.allMedia, .allLocations]
    }
    
    static var cloudDriveImages: PhotosFilterOptions {
        return [.images, .cloudDrive]
    }
    
    static var cloudDriveVideos: PhotosFilterOptions {
        return [.videos, .cloudDrive]
    }
    
    static var cloudDriveAll: PhotosFilterOptions {
        return [.allMedia, .cloudDrive]
    }
    
    static var cameraUploadImages: PhotosFilterOptions {
        return [.images, .cameraUploads]
    }
    
    static var cameraUploadVideos: PhotosFilterOptions {
        return [.videos, .cameraUploads]
    }
    
    static var cameraUploadAll: PhotosFilterOptions {
        return [.allMedia, .cameraUploads]
    }
}
