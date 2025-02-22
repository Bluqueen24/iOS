public enum DeviceCenterActionType {
    case cameraUploads
    case info
    case rename
    case showInCloudDrive
    case showInBackups
    case sort
    case sortAscending
    case sortDescending
    case sortLargest
    case sortSmallest
    case sortNewest
    case sortOldest
    case sortLabel
    case sortFavourite
}

public struct DeviceCenterAction: Hashable {
    let type: DeviceCenterActionType
    let title: String
    let subtitle: String?
    var dynamicSubtitle: (() -> String)?
    let icon: String
    let subActions: [DeviceCenterAction]?

    public init(type: DeviceCenterActionType, title: String, subtitle: String? = nil, dynamicSubtitle: (() -> String)? = nil, icon: String, subActions: [DeviceCenterAction]? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.dynamicSubtitle = dynamicSubtitle
        self.icon = icon
        self.subActions = subActions
    }
    
    public static func == (lhs: DeviceCenterAction, rhs: DeviceCenterAction) -> Bool {
        lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
