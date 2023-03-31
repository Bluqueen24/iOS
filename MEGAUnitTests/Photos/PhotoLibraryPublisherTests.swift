import XCTest
@testable import MEGA

final class PhotoLibraryPublisherTests: XCTestCase {
    func testSubscribeToPhotoSelectionHidden_onSelectionHiddenChange_shouldChangeClosureValue() {
        let viewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                     contentMode: .library)
        let sut = PhotoLibraryPublisher(viewModel: viewModel)
        let exp = expectation(description: "Should update on selection hidden change")
        exp.expectedFulfillmentCount = 3
        var results = [Bool]()
        sut.subscribeToPhotoSelectionHidden {
            results.append($0)
            exp.fulfill()
        }
        viewModel.selection.isHidden = true
        viewModel.selection.isHidden = false
        XCTAssertEqual(results, [false, true, false])
        wait(for: [exp], timeout: 1.0)
    }
}
