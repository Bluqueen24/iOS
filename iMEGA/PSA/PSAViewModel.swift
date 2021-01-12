
enum PSAViewAction: ActionType {
    case onViewReady
}

@objc
final class PSAViewModel: NSObject, ViewModelType {
    
    private let router: PSAViewRouter
    private let useCase: PSAUseCase
    private var psaEntity: PSAEntity?
    
    enum Command: CommandType {
        case configView(PSAEntity)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(router: PSAViewRouter, useCase: PSAUseCase) {
        self.router = router
        self.useCase = useCase
    }
    
    func dispatch(_ action: PSAViewAction) {
        switch action {
        case .onViewReady:
            if let psaEntity = psaEntity {
                invokeCommand?(.configView(psaEntity))
            }
            getPSA()
        }
    }
    
    func shouldShowView(completion: @escaping ((Bool) -> Void)) {
        useCase.getPSA { [weak self] result in
            switch result {
            case .success(let psaEntity):
                self?.psaEntity = psaEntity
                completion(true)
            case .failure(_):
                completion(false)
            }
        }
    }
    
    private func getPSA() {
        useCase.getPSA { result in
            switch result {
            case .success(let psaEntity):
                self.invokeCommand?(.configView(psaEntity))
            case .failure(let error):
                dump(error)
            }
        }
    }
}
