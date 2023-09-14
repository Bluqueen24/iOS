import Combine
import MEGADomain
import MEGAL10n

final class ReportIssueViewModel: ObservableObject {
    private let router: any ReportIssueViewRouting
    private let uploadFileUseCase: any UploadFileUseCaseProtocol
    private let supportUseCase: any SupportUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var transfer: TransferEntity?
    private var sourceUrl: URL?
    private var detailsPlaceholder = Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder
    private var subscriptions: AnyCancellable?
    private let monitorUseCase: any NetworkMonitorUseCaseProtocol
    private var reportAlertType: ReportIssueAlertTypeModel = .none
    
    var areLogsEnabled: Bool
    var shouldDisableSendButton: Bool {
        details.isEmpty || details == detailsPlaceholder || !isConnected
    }
    
    var shouldShowUploadLogFileView: Bool {
        isUploadingLog && areLogsEnabled && isSendLogFileToggleOn
    }
    
    var isReportDiscardable: Bool {
        !(details.isEmpty || details == detailsPlaceholder)
    }
    
    @Published var progress: Float = 0
    @Published var isUploadingLog = false
    @Published var details = ""
    @Published var isConnected = true
    @Published var showingReportIssueActionSheet = false
    @Published var showingReportIssueAlert = false
    
    var isSendLogFileToggleOn = true
    
    init(router: some ReportIssueViewRouting,
         uploadFileUseCase: any UploadFileUseCaseProtocol,
         supportUseCase: any SupportUseCaseProtocol,
         monitorUseCase: any NetworkMonitorUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         areLogsEnabled: Bool = false,
         sourceUrl: URL?
    ) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.sourceUrl = sourceUrl
        self.areLogsEnabled = areLogsEnabled
        self.supportUseCase = supportUseCase
        self.monitorUseCase = monitorUseCase
        self.accountUseCase = accountUseCase
        self.monitorUseCase.networkPathChanged(completion: { [weak self] (isConnected) in
            self?.isConnected = isConnected
        })
    }
    
    private func uploadLogFileIfNeeded() {
        guard let sourceUrl else {
            createTicketForSupport()
            return
        }
        uploadFileUseCase.uploadSupportFile(sourceUrl) { [weak self] (transferEntity) in
            DispatchQueue.main.async {
                self?.transfer = transferEntity
                self?.isUploadingLog = true
            }
        } progress: { [weak self] (transferEntity) in
            DispatchQueue.main.async {
                self?.progress = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
            }
        } completion: { [weak self] (result) in
            DispatchQueue.main.async {
                self?.isUploadingLog = false
                switch result {
                case .failure:
                    self?.reportAlertType = .uploadLogFileFailure
                    self?.showingReportIssueAlert = true
                case .success(let transferEntity):
                    self?.progress = 100
                    self?.createTicketForSupport(filename: transferEntity.fileName)
                }
            }
        }
    }
    
    private func createTicketForSupport(filename: String? = nil) {
        Task { @MainActor in
            do {
                try await supportUseCase.createSupportTicket(withMessage: getFormattedReportIssueMessage(details, filename: filename))
                reportAlertType = .createSupportTicketFinished
            } catch {
                reportAlertType = .createSupportTicketFailure
            }
            showingReportIssueAlert = true
        }
    }
    
    @MainActor
    private func getFormattedReportIssueMessage(_ message: String, filename: String? = nil) async -> String {
        let appMetaDataFactory = AppMetaDataFactory(bundle: .main)
        let deviceMetaDataFactory = DeviceMetaDataFactory(bundle: .main, locale: NSLocale.current as NSLocale)
        let messageViewModel = ReportIssueMessageViewModel(accountUseCase: accountUseCase, appMetaData: appMetaDataFactory.make(), deviceMetaData: deviceMetaDataFactory.make())
        return await messageViewModel.generateReportIssueMessage(message: message, filename: filename ?? "No log file")
    }
    
    func createTicket() {
        if isSendLogFileToggleOn && areLogsEnabled {
            uploadLogFileIfNeeded()
        } else {
            createTicketForSupport()
        }
    }
    
    func dismissReport() {
        router.dismiss()
    }
    
    func cancelUploadReport() {
        guard let transfer else {
            router.dismiss()
            return
        }
        uploadFileUseCase.cancel(transfer: transfer) { [weak self] (result) in
            switch result {
            case .success:
                MEGALogDebug("[Report issue] report canceled")
            case .failure:
                MEGALogError("[Report issue] fail cancel the report")
                self?.router.dismiss()
            }
        }
    }
    
    func showCancelUploadReportAlert() {
        reportAlertType = .cancelUploadReport
        showingReportIssueAlert = true
    }
    
    func showReportIssueActionSheetIfNeeded() {
        showingReportIssueActionSheet = isReportDiscardable
        if !showingReportIssueActionSheet {
            dismissReport()
        }
    }
    
    func reportIssueAlertData() -> ReportIssueAlertDataModel {
        switch reportAlertType {
        case .uploadLogFileFailure, .createSupportTicketFailure:
            return ReportIssueAlertDataModel(title: Strings.Localizable.somethingWentWrong,
                                             message: Strings.Localizable.Help.ReportIssue.Fail.message,
                                             primaryButtonTitle: Strings.Localizable.ok)
        case .createSupportTicketFinished:
            return ReportIssueAlertDataModel(title: Strings.Localizable.Help.ReportIssue.Success.title,
                                             message: Strings.Localizable.Help.ReportIssue.Success.message,
                                             primaryButtonTitle: Strings.Localizable.ok,
                                             primaryButtonAction: dismissReport)
        case .cancelUploadReport:
            return ReportIssueAlertDataModel(title: Strings.Localizable.Help.ReportIssue.Creating.Cancel.title,
                                             message: Strings.Localizable.Help.ReportIssue.Creating.Cancel.message,
                                             primaryButtonTitle: Strings.Localizable.continue,
                                             primaryButtonAction: dismissReport,
                                             secondaryButtoTitle: Strings.Localizable.yes,
                                             secondaryButtonAction: cancelUploadReport)
        case .none:
            return ReportIssueAlertDataModel()
        }
    }
}
