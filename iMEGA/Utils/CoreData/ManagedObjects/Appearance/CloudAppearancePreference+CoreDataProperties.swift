import CoreData
import Foundation

extension CloudAppearancePreference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CloudAppearancePreference> {
        return NSFetchRequest<CloudAppearancePreference>(entityName: "CloudAppearancePreference")
    }

    @NSManaged public var handle: NSNumber?

}
