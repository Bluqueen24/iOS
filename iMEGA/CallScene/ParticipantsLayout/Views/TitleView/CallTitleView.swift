import Foundation

class CallTitleView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet weak var recordingImageView: UIImageView!
    
    override var intrinsicContentSize: CGSize {
       return UIView.layoutFittingExpandedSize
     }
    
    internal func configure(title: String?, subtitle: String?) {
        if title != nil {
            titleLabel.text = title
        }
        if subtitle != nil {
            subtitleLabel.text = subtitle
        }
    }
    
    func hideRecordingIndicator(_ hidden: Bool) {
        recordingImageView.isHidden = hidden
    }
}
