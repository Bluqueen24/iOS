@testable import MEGA

class MockRenameViewRouter: RenameViewRouting {
    var didFinishSuccessfullyCalled = false
    var didFinishWithErrorCalled = false
    
    func renamingFinished(with result: Result<Void, Error>) {
        switch result {
        case .success:
            didFinishSuccessfullyCalled = true
        case .failure:
            didFinishWithErrorCalled = true
        }
    }
}
