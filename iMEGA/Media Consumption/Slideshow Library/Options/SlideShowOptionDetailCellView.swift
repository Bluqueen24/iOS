import SwiftUI
import UIKit

struct SlideShowOptionDetailCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionDetailCellViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = viewModel.image {
                    Image(uiImage: icon)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                
                Text(viewModel.title)
                    .font(.body)
                    .padding(.vertical, 13)
                
                Spacer()
                Image(uiImage: UIImage.turquoiseCheckmark)
                    .scaledToFit()
                    .opacity(viewModel.isSelcted ? 1 : 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            Divider().padding(.leading, 16)
        }
        .background(colorScheme == .dark ? MEGAAppColor.Black._2C2C2E.color : MEGAAppColor.White._FFFFFF.color)
    }
}
