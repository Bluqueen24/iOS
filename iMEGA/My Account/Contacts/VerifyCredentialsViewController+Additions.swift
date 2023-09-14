import MEGAL10n

extension VerifyCredentialsViewController {
    
    @objc func setContentMessages() {
        navigationItem.title = Strings.Localizable.verifyCredentials
        myCredentialsHeaderLabel.text = Strings.Localizable.SharedItems.ContactVerification.Section.MyCredentials.message

        if isVerifyContactForSharedItem {
            contactHeaderLabel.text = isIncomingSharedItem ?
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Receiver.message:
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Owner.message
        } else {
            contactHeaderLabel.text = Strings.Localizable.VerifyCredentials.headerMessage
        }
    }

    @objc func setLabelColors() {
        contactHeaderLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        myCredentialsHeaderLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)
    }
}
