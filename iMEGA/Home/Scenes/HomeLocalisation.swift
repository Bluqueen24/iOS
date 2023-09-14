import Foundation
import MEGAL10n

enum HomeLocalisation: String {

    // MARK: - File Uploading Options

    case photos
    case textFile
    case capture
    case imports
    case documentScan

    // MARK: - Upload From Album TableView

    case upload

    // MARK: - Search Bar

    case searchYourFiles

    var rawValue: String {
        switch self {
        case .photos:
            return Strings.Localizable.choosePhotoVideo
        case .textFile:
            return Strings.Localizable.newTextFile
        case .capture:
            return Strings.Localizable.capturePhotoVideo
        case .imports:
            return Strings.Localizable.CloudDrive.Upload.importFromFiles
        case .documentScan:
            return Strings.Localizable.scanDocument
        case .upload:
            return Strings.Localizable.upload
        case .searchYourFiles:
            return Strings.Localizable.searchYourFiles
        }
    }
}
