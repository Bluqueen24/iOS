import MEGAL10n

extension MEGANode {

    /// Create an NSAttributedString with the name of the node and append isTakedown image
    /// - Returns: The name of the node appending isTakedown image at the end
    @objc func attributedTakenDownName() -> NSAttributedString {
        let name = NSMutableAttributedString(string: self.name?.appending(" ") ?? "")

        let takedownImageAttachment = NSTextAttachment()
        takedownImageAttachment.image = UIImage(named: "isTakedown")
        let takedownImageString = NSAttributedString(attachment: takedownImageAttachment)
        
        name.append(takedownImageString)
        
        return name
    }
    
    @objc func fileFolderRenameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.rename
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
    }
    
    @objc func alertMessage(forRemoved nodeType: MEGANodeType) -> String {
        Strings.Localizable.SharedItems.Rubbish.Warning.message(
            (nodeType == .folder) ? Strings.Localizable.SharedItems.Rubbish.Warning.folderCount(1) : Strings.Localizable.SharedItems.Rubbish.Warning.fileCount(1)
        )
    }
}
