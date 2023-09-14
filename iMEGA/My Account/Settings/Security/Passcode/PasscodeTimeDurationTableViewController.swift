import MEGAL10n
import UIKit

@objc enum RequirePasscodeAfter: Int {
    case Immediatelly = -1
    case FiveSeconds = 5
    case TenSeconds = 10
    case ThirtySeconds = 30
    case OneMinute = 60
    case TwoMinutes = 120
    case FiveMinutes = 300
}

class PasscodeTimeDurationTableViewController: UITableViewController {

    private let cellReuseId = "tableViewCellId"

    private var passcodeDurationInfoArray: [PasscodeDurationInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        title = Strings.Localizable.requirePasscode

        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.Immediatelly, title: Strings.Localizable.immediately))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveSeconds, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveSeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TenSeconds, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TenSeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.ThirtySeconds, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.ThirtySeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.OneMinute, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.OneMinute.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TwoMinutes, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TwoMinutes.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveMinutes, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveMinutes.rawValue)))
        
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
    
    // MARK: - Private
    
    func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passcodeDurationInfoArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        cell.textLabel?.textColor = UIColor.mnz_label()
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.text = passcodeDurationInfoArray[indexPath.row].title

        let timerDuration = LTHPasscodeViewController.timerDuration()

        if Int(timerDuration) == passcodeDurationInfoArray[indexPath.row].duration.rawValue {
            cell.accessoryView = UIImageView.init(image: Asset.Images.Generic.turquoiseCheckmark.image)
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        LTHPasscodeViewController.saveTimerDuration(TimeInterval(passcodeDurationInfoArray[indexPath.row].duration.rawValue))
        tableView.reloadData()
    }

}
