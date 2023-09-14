import Combine
@testable import MEGA
import MEGADomain
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Plans
    func testAccountPlanProducts_monthly() async {
        let products = [MockSKProduct(identifier: "pro1.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneMonth", price: "1", priceLocale: Locale.current)]
        let expectedResult = [AccountPlanEntity(type: .proI, subscriptionCycle: .monthly),
                              AccountPlanEntity(type: .proII, subscriptionCycle: .monthly),
                              AccountPlanEntity(type: .proIII, subscriptionCycle: .monthly),
                              AccountPlanEntity(type: .lite, subscriptionCycle: .monthly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    func testAccountPlanProducts_yearly() async {
        let products = [MockSKProduct(identifier: "pro1.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneYear", price: "1", priceLocale: Locale.current)]
        let expectedResult = [AccountPlanEntity(type: .proI, subscriptionCycle: .yearly),
                              AccountPlanEntity(type: .proII, subscriptionCycle: .yearly),
                              AccountPlanEntity(type: .proIII, subscriptionCycle: .yearly),
                              AccountPlanEntity(type: .lite, subscriptionCycle: .yearly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    // MARK: Restore purchase
    func testRestorePurchase_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchase_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerRestoreDelegate()
        
        await sut.deRegisterRestoreDelegate()
        XCTAssertFalse(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseCalled_shouldReturnTrue() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.restorePurchase()
        XCTAssertTrue(mockPurchase.restorePurchaseCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from successfulRestorePublisher")
        sut.successfulRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.successfulRestore(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_incompleteRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from incompleteRestorePublisher")
        sut.incompleteRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.incompleteRestore()
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_failedRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "Test Error")
        sut.failedRestorePublisher
            .sink { errorEntity in
                XCTAssertEqual(errorEntity.errorCode, expectedError.errorCode)
                XCTAssertEqual(errorEntity.errorMessage, expectedError.errorMessage)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.failedRestore(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Purchase plan
    func testPurchasePlan_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePlan_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerPurchaseDelegate()
        
        await sut.deRegisterPurchaseDelegate()
        XCTAssertFalse(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePublisher_successPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive success purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.successfulPurchase(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testPurchasePublisher_failedPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        
        let exp = expectation(description: "Should receive success purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedPurchase(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
}
