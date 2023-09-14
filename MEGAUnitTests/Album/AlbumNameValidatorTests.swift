@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class AlbumNameValidatorTests: XCTestCase {

    func testCreate_whenNameIsNil_shouldReturnNil() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = ""
        XCTAssertNil(sut.create(testName))
    }
    
    func testRename_whenNameIsNil_shouldReturnErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = ""
        let targetError = TextFieldAlertError(title: "", description: "")
        
        XCTAssertEqual(sut.rename(testName), targetError)
    }
    
    func testValidate_whenNameHasEmptySpaces_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = "       "
        let targetError = TextFieldAlertError(title: "", description: "")
        
        XCTAssertEqual(sut.create(testName), targetError)
    }
    
    func testValidate_whenNameHasInvalidChars_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = "* adkd"
        let targetError = TextFieldAlertError(title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters), description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterNewName)
        
        XCTAssertEqual(sut.create(testName), targetError)
    }
    
    func testValidate_whenNameHasReservedAlbumNames_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = Strings.Localizable.CameraUploads.Albums.Favourites.title
        let targetError = TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.albumNameNotAllowed, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        
        XCTAssertEqual(sut.create(testName), targetError)
    }

    func testValidate_whenNameHasExistingAlbumNames_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {["aaa", "bbb"]})
        let testName = "aaa"
        let targetError = TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.userAlbumExists, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        
        XCTAssertEqual(sut.create(testName), targetError)
    }
    
    func testValidate_whenNameHasValidName_shouldReturnNil() {
        let sut = AlbumNameValidator(existingAlbumNames: {["aaa", "bbb"]})
        let testName = "Hey there this is a new album"
        
        XCTAssertNil(sut.create(testName))
    }
    
}
