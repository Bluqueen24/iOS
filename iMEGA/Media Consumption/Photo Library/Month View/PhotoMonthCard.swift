import SwiftUI

struct PhotoMonthCard: View {
    @StateObject var viewModel: PhotoMonthCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            if #available(iOS 15.0, *) {
                Text(viewModel.attributedTitle)
            } else {
                Text(viewModel.title)
                    .font(.title2.bold())
            }
        }
    }
}
