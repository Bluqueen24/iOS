import DeviceCenter
import DeviceCenterMocks
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class MyAccountHallViewModelTests: XCTestCase {

    func testAction_onViewAppear() {
        let (sut, _) = makeSUT()
        test(viewModel: sut,
             actions: [MyAccountHallAction.reloadUI],
             expectedCommands: [.reloadUIContent])
    }
    
    func testAction_loadPlanList() async {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }

        sut.dispatch(.load(.planList))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(commands, [.configPlanDisplay])
    }
    
    func testAction_loadContentCounts() async {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }

        sut.dispatch(.load(.contentCounts))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(commands, [.reloadCounts])
    }
    
    func testAction_loadAccountDetails() async {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }

        sut.dispatch(.load(.accountDetails))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(commands, [.configPlanDisplay])
    }
    
    func testAction_addSubscriptions() {
        let (sut, _) = makeSUT()
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.addSubscriptions],
             expectedCommands: [])
    }
    
    func testAction_removeSubscriptions() {
        let (sut, _) = makeSUT()
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.removeSubscriptions],
             expectedCommands: [])
    }
    
    func testInitAccountDetails_shouldHaveCorrectDetails() {
        let expectedAccountDetails = AccountDetailsEntity.random
        let (sut, _) = makeSUT(currentAccountDetails: expectedAccountDetails)
    
        XCTAssertEqual(sut.accountDetails, expectedAccountDetails)
    }

    func testIsMasterBusinessAccount_shouldBeTrue() {
        let (sut, _) = makeSUT(isMasterBusinessAccount: true)
        XCTAssertTrue(sut.isMasterBusinessAccount)
    }
    
    func testIsMasterBusinessAccount_shouldBeFalse() {
        let (sut, _) = makeSUT(isMasterBusinessAccount: false)
        XCTAssertFalse(sut.isMasterBusinessAccount)
    }
    
    func testAction_didTapUpgradeButton_showUpgradeView() {
        let (sut, _) = makeSUT()
        
        test(viewModel: sut, actions: [MyAccountHallAction.didTapUpgradeButton], expectedCommands: [])
    }
    
    func testIsFeatureFlagEnabled_onDeviceCenterUIEnabled_shouldBeEnabled() {
        let (sut, _) = makeSUT(featureFlagProvider: MockFeatureFlagProvider(list: [.deviceCenter: true]))
        XCTAssertTrue(sut.isDeviceCenterEnabled())
    }

    func testIsFeatureFlagEnabled_onDeviceCenterUIDisabled_shouldBeTurnedOff() {
        let (sut, _) = makeSUT(featureFlagProvider: MockFeatureFlagProvider(list: [.deviceCenter: false]))
        XCTAssertFalse(sut.isDeviceCenterEnabled())
    }
    
    func testIsFeatureFlagEnabled_onNotificationCenterUIEnabled_shouldBeEnabled() {
        let (sut, _) = makeSUT(featureFlagProvider: MockFeatureFlagProvider(list: [.notificationCenter: true]))
        XCTAssertTrue(sut.isNotificationCenterEnabled())
    }

    func testIsFeatureFlagEnabled_onNotificationCenterUIDisabled_shouldBeTurnedOff() {
        let (sut, _) = makeSUT(featureFlagProvider: MockFeatureFlagProvider(list: [.notificationCenter: false]))
        XCTAssertFalse(sut.isNotificationCenterEnabled())
    }
    
    func testDidTapDeviceCenterButton_whenButtonIsTapped_navigatesToDeviceCenter() {
        let (sut, router) = makeSUT()
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        XCTAssertEqual(router.navigateToDeviceCenter_calledTimes, 1)
    }
    
    func testDidTapCameraUploadsAction_whenCameraUploadActionTapped_callsRouterOnce() {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.cameraUploadActionTapped({})
        
        XCTAssertEqual(
            router.didTapCameraUploadsAction_calledTimes, 1, "Camera upload action should have called the router once"
        )
    }
    
    func testDidTapRenameAction_whenRenameActionTapped_callsRouterOnce() {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.renameActionTapped(
            RenameActionEntity(
                oldName: "",
                otherNamesInContext: [],
                actionType: .device(deviceId: "", maxCharacters: 32),
                alertTitles: [:],
                alertMessage: [:],
                alertPlaceholder: "",
                renamingFinished: {}
            )
        )
        
        XCTAssertEqual(
            router.didTapRenameAction_calledTimes, 1, "Rename node action should have called the router once"
        )
    }
    
    func testDidTapShowIn_whenShowInActionTapped_callsRouterOnce() async throws {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.showInTapped(
            NavigateToContentActionEntity(
                type: .showInBackups,
                node: MockNode(handle: 1).toNodeEntity(),
                error: nil
            )
        )
        
        XCTAssertEqual(
            router.didTapShowInAction_calledTimes, 1, "Show in action should have called the router once"
        )
    }
    
    func testDidTapInfoAction_whenInfoActionTapped_callsRouterOnce() async throws {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.infoActionTapped(
            ResourceInfoModel(
                icon: "",
                name: "",
                counter: ResourceCounter.emptyCounter
            )
        )
        
        XCTAssertEqual(
            router.didTapInfoAction_calledTimes, 1, "Info action should have called the router once"
        )
    }
    
    private func makeSUT(
        isMasterBusinessAccount: Bool = false,
        currentAccountDetails: AccountDetailsEntity? = nil,
        featureFlagProvider: MockFeatureFlagProvider = MockFeatureFlagProvider(list: [:]),
        deviceCenterBridge: DeviceCenterBridge = DeviceCenterBridge()
    ) -> (MyAccountHallViewModel, MockMyAccountHallRouter) {
        let myAccountHallUseCase = MockMyAccountHallUseCase(
            currentAccountDetails: currentAccountDetails ?? AccountDetailsEntity.random,
            isMasterBusinessAccount: isMasterBusinessAccount
        )
        
        let purchaseUseCase = MockAccountPlanPurchaseUseCase()
        let shareUseCase = MockShareUseCase()
        let router = MockMyAccountHallRouter()
        
        return (
            MyAccountHallViewModel(
                myAccountHallUseCase: myAccountHallUseCase,
                purchaseUseCase: purchaseUseCase, 
                shareUseCase: shareUseCase,
                featureFlagProvider: featureFlagProvider,
                deviceCenterBridge: deviceCenterBridge,
                router: router
            ), router
        )
    }
}
