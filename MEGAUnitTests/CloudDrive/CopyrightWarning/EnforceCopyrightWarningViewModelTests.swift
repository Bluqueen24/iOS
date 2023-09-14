import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class EnforceCopyrightWarningViewModelTests: XCTestCase {
    private var subscription = Set<AnyCancellable>()
    
    func testDetermineViewState_noAutoApproval_shouldReturnDeclined() async {
        let copyrightUseCase = MockCopyrightUseCase(shouldAutoApprove: false)
        let sut = makeEnforceCopyrightWarningViewModel(copyrightUseCase: copyrightUseCase)
        XCTAssertEqual(sut.viewStatus, .unknown)
        
        await sut.determineViewState()
        
        XCTAssertEqual(sut.viewStatus, .declined)
    }
    
    func testDetermineViewState_agreedBefore_shouldReturnAgreed() async {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.agreedCopywriteWarning: true])
        let copyrightUseCase = MockCopyrightUseCase(shouldAutoApprove: false)
        let sut = makeEnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                       copyrightUseCase: copyrightUseCase)
        
        await sut.determineViewState()
        
        XCTAssertEqual(sut.viewStatus, .agreed)
    }
    
    func testDetermineViewState_copyrightShouldAutoApprove_shouldSetToAgreedReturnAgreed() async throws {
        let preferenceUseCase = MockPreferenceUseCase()
        let copyrightUseCase = MockCopyrightUseCase(shouldAutoApprove: true)
        let sut = makeEnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                       copyrightUseCase: copyrightUseCase)
        
        await sut.determineViewState()
        
        let isAgreed = try XCTUnwrap(preferenceUseCase.dict[.agreedCopywriteWarning] as? Bool)
        XCTAssertTrue(isAgreed)
        XCTAssertEqual(sut.viewStatus, .agreed)
    }
    
    func testIsTermsAgreed_onAgreed_shouldSetPreferenceAndEmitAgreedViewStatus() throws {
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = makeEnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase)
        
        let exp = expectation(description: "view status should change to agreed")
        sut.$viewStatus
            .dropFirst()
            .sink {
                XCTAssertEqual($0, .agreed)
                exp.fulfill()
            }
            .store(in: &subscription)
        
        sut.isTermsAgreed = true
        
        wait(for: [exp], timeout: 0.5)
        let isAgreed = try XCTUnwrap(preferenceUseCase.dict[.agreedCopywriteWarning] as? Bool)
        XCTAssertTrue(isAgreed)
    }
    
    func testCopyrightMessage_shouldBeCombinedFromTwoParts() {
        let sut = makeEnforceCopyrightWarningViewModel()
        
        let expectedCopyrightMessage = "\(Strings.Localizable.copyrightMessagePart1)\n\n\(Strings.Localizable.copyrightMessagePart2)"
        XCTAssertEqual(sut.copyrightMessage, expectedCopyrightMessage)
    }
    
    // MARK: - Helpers
    
    private func makeEnforceCopyrightWarningViewModel(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        copyrightUseCase: some CopyrightUseCaseProtocol = MockCopyrightUseCase()
    ) -> EnforceCopyrightWarningViewModel {
        EnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                         copyrightUseCase: copyrightUseCase)
    }
}
