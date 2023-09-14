import Contacts
import Intents

public extension Array where Element: CNContact {
    func persons(withDisplayName displayName: String) -> [INPerson] {
        let persons = self.flatMap { contact -> [INPerson] in
            let persons = contact.emailAddresses.compactMap {
                let personHandle = INPersonHandle(value: $0.value as String, type: .emailAddress)
                return INPerson(
                    personHandle: personHandle,
                    nameComponents: nil,
                    displayName: displayName,
                    image: nil, contactIdentifier: nil, customIdentifier: nil
                )
            }
            return persons
        }
        return persons
    }

    func extractEmails() -> [String] {
        self
            .compactMap { $0.emailAddresses.first?.value as String? }
    }

    func extractPhoneNumbers() -> [String] {
        self
            .compactMap { $0.phoneNumbers.first?.value.stringValue }
    }
}
