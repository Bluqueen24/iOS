import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

final class SlideShowOptionRouter: Routing {
    private weak var presenter: UIViewController?
    private var preference: any SlideShowViewModelPreferenceProtocol
    private let currentConfiguration: SlideShowConfigurationEntity
    private var newConfiguration: SlideShowConfigurationEntity
    private let tracker: any AnalyticsTracking

    init(
        presenter: UIViewController?,
        preference: some SlideShowViewModelPreferenceProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        currentConfiguration: SlideShowConfigurationEntity
    ) {
        self.presenter = presenter
        self.preference = preference
        self.tracker = tracker
        self.currentConfiguration = currentConfiguration
        newConfiguration = currentConfiguration
    }
    
    func build() -> UIViewController {
        let viewModel = SlideShowOptionViewModel(cellViewModels: makeCells(withConfiguration: currentConfiguration), currentConfiguration: currentConfiguration)
        return UIHostingController(rootView: SlideShowOptionView(viewModel: viewModel, preference: preference, router: SlideShowOptionContentRouter(), dismissal: dismiss))
    }
    
    func start() {
        let vc = build()
        presenter?.modalPresentationStyle = .overCurrentContext
        presenter?.present(vc, animated: true)
    }
    
    func dismiss() {
        presenter?.dismiss(animated: true)
    }
}

extension SlideShowOptionRouter {
    @SlideShowOptionBuilder
    private func makeCells(withConfiguration config: SlideShowConfigurationEntity) -> [SlideShowOptionCellViewModel] {
        SlideShowOptionCellViewModel(name: .speed, title: Strings.Localizable.Slideshow.PreferenceSetting.speed, type: .detail, children: makeChildrenForSlideShowSpeed(withConfiguration: config), tracker: tracker)
        SlideShowOptionCellViewModel(name: .order, title: Strings.Localizable.Slideshow.PreferenceSetting.order, type: .detail, children: makeChildrenForSlideShowOrder(withConfiguration: config), tracker: tracker)
        SlideShowOptionCellViewModel(name: .repeat, title: Strings.Localizable.Slideshow.PreferenceSetting.SlideshowOptions.repeat, type: .toggle, children: [], isOn: config.isRepeat, tracker: tracker)
    }
    
    @SlideShowOptionChildrenBuilder
    private func makeChildrenForSlideShowSpeed(withConfiguration config: SlideShowConfigurationEntity) -> [SlideShowOptionDetailCellViewModel] {
        SlideShowOptionDetailCellViewModel(
            name: .speedSlow,
            title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow,
            isSelcted: config.timeIntervalForSlideInSeconds == .slow)
        SlideShowOptionDetailCellViewModel(
            name: .speedNormal,
            title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.normal,
            isSelcted: config.timeIntervalForSlideInSeconds == .normal)
        SlideShowOptionDetailCellViewModel(
            name: .speedFast,
            title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.fast,
            isSelcted: config.timeIntervalForSlideInSeconds == .fast)
    }
    
    @SlideShowOptionChildrenBuilder
    private func makeChildrenForSlideShowOrder(withConfiguration config: SlideShowConfigurationEntity) -> [SlideShowOptionDetailCellViewModel] {
        SlideShowOptionDetailCellViewModel(name: .orderShuffle,
                                           image: UIImage.shuffleAudio,
                                           title: Strings.Localizable.Slideshow.PreferenceSetting.Order.shuffle,
                                           isSelcted: config.playingOrder == .shuffled)
        SlideShowOptionDetailCellViewModel(name: .orderNewest,
                                           image: UIImage.newest,
                                           title: Strings.Localizable.newest,
                                           isSelcted: config.playingOrder == .newest)
        SlideShowOptionDetailCellViewModel(name: .orderOldest,
                                           image: UIImage.oldest,
                                           title: Strings.Localizable.oldest,
                                           isSelcted: config.playingOrder == .oldest)
    }
}
