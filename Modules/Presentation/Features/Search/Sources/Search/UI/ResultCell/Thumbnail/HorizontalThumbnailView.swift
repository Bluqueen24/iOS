import SwiftUI

// MAKE SCREEN WIDE TO SEE DOCUMENTATION
// ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
// │╔═════════════╗╔══════════════════════╗┌────────────┐                                                          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// │║             ║║       [TITLE]        ║│ .prominent │                                                                             ││
// │║             ║╚══════════════════════╝└────────────┘                                                          │                   │
// │║             ║                                                                                                        Menu       ││
// │║    Icon     ║                                                                                                │(optional, hidden  │
// │║             ║                                                                                                 in selection mode)││
// │║             ║╔═══════════════╗┌──────────────────────┐┌────────────────────────┐┌───────────────────────────┐│                   │
// │║             ║║  [SUBTITLE]   ║│ .secondary(.leading) ││ .secondary(.trailing)  ││ .secondary(.trailingEdge) │                   ││
// │╚═════════════╝╚═══════════════╝└──────────────────────┘└────────────────────────┘└───────────────────────────┘└ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
// └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

struct HorizontalThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionEnabled: Bool
    
    private let layout: ResultCellLayout = .thumbnail(.horizontal)
    
    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: 8) {
                thumbnailImage
                
                VStack(alignment: .leading, spacing: .zero) {
                    titleAndLabel
                    infoAndIcons
                }
                .padding(.vertical, 8)
            }
            Spacer()
            trailingView
        }
        .padding(.leading, 9)
        .padding(.trailing, 8)
        .frame(height: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var thumbnailImage: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }
    
    private var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    private var titleAndLabel: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.title)
                .font(.system(size: 12, weight: .medium))
                .titleTextColor(
                    colorAssets: viewModel.colorAssets,
                    hasVibrantTitle: viewModel.hasVibrantTitle
                )
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .prominent)
        }
        .frame(height: 12)
    }
    
    private var infoAndIcons: some View {
        HStack(spacing: 4) {
            Text(viewModel.result.description(layout))
                .font(.caption)
                .foregroundColor(.primary)
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.leading))
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.trailing))
            
            viewModel
                .result
                .properties
                .propertyViewsFor(layout: layout, placement: .secondary(.trailingEdge))
            
        }
    }
    
    @ViewBuilder var trailingView: some View {
        if selectionEnabled {
            selectionIcon
        } else {
            moreButton
        }
    }
    
    @ViewBuilder var selectionIcon: some View {
        Image(
            uiImage: isSelected ?
            viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
        )
        .resizable()
        .scaledToFit()
        .frame(width: 22, height: 22)
    }
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreList
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 24, height: 24)
    }
    
    private var borderColor: Color {
        if selectionEnabled && isSelected {
            viewModel.colorAssets._00A886
        } else {
            colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._545458
        }
    }
}
