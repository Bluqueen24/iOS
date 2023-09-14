import Firebase
import Intents
import MEGAIntentDomain
import MEGARepo

final class IntentHandler: INExtension {
    lazy var intentPersonUseCase = IntentPersonUseCase(repository: ContactsRepository.newRepo)

    override init() {
        super.init()
        FirebaseApp.configure()
    }

    override func handler(for intent: INIntent) -> Any {
        self
    }
}

extension IntentHandler: SelectShortcutIntentHandling {
    func provideShortcutOptionsCollection(for intent: SelectShortcutIntent, with completion: @escaping (INObjectCollection<IntentShortcut>?, Error?) -> Void) {
        let intentShortcuts = ShortcutDetail.availableShortcuts.map {
            IntentShortcut(identifier: $0.link, display: $0.title)
        }
        completion(INObjectCollection(items: intentShortcuts), nil)
    }
    
    func defaultShortcut(for intent: SelectShortcutIntent) -> [IntentShortcut]? {
        ShortcutDetail.availableShortcuts.map {
            IntentShortcut(identifier: $0.link, display: $0.title)
        }
    }
}
