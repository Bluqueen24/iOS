import SwiftUI

struct SlideShowOptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionViewModel
    let preference: any SlideShowViewModelPreferenceProtocol
    let router: any SlideShowOptionContentRouting
    var dismissal: () -> Void
    
    var body: some View {
        ZStack {
            backgroundColor
            VStack(spacing: 0) {
                navigationBar
                listView()
            }
        }
        .sheet(isPresented: $viewModel.shouldShowDetail) {
            detailView()
        }
        .onDisappear {
            preference.restart(withConfig: viewModel.configuration())
        }
    }
    
    var navBarButton: some View {
        Button {
            dismissal()
        } label: {
            Text(viewModel.doneButtonTitle)
                .font(.body.bold())
                .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color)
                .padding()
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        Text(viewModel.navigationTitle)
            .font(.body.bold())
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    navBarButton
                }
            )
            .padding(.top, 28)
    }
    
    @ViewBuilder func listView() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Divider()
                ForEach(viewModel.cellViewModels, id: \.self.id) { cellViewModel in
                    router.slideShowOptionCell(for: cellViewModel)
                        .onTapGesture {
                            viewModel.didSelectCell(cellViewModel)
                        }
                }
                Divider()
            }
        }
        .padding(.top, 36)
    }
    
    @ViewBuilder func detailView() -> some View {
        if viewModel.shouldShowDetail {
            router.slideShowOptionDetailView(for: viewModel.selectedCell, isShowing: $viewModel.shouldShowDetail)
        }
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark: return MEGAAppColor.Black._1C1C1E.color
        default: return MEGAAppColor.White._F7F7F7.color
        }
    }
}
