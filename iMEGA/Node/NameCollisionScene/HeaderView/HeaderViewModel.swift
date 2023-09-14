import MEGAL10n

final class HeaderViewModel: ObservableObject {
    private let isFile: Bool
    private let name: String
    
    init(isFile: Bool, name: String) {
        self.isFile = isFile
        self.name = name
    }
    
    var titleComponents: [String] {
        let stringComponents = (isFile ? Strings.Localizable.NameCollision.Files.alreadyExists(name) : Strings.Localizable.NameCollision.Folders.alreadyExists(name)).components(separatedBy: name)
        return [stringComponents[safe: 0] ?? "", name, stringComponents[safe: 1] ?? ""]
    }
}
