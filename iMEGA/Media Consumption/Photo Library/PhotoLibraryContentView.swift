import SwiftUI

struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    var router: any PhotoLibraryContentViewRouting
    let onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        Group {
            if viewModel.library.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                Group {
                    if #available(iOS 15.0, *) {
                        content()
                    } else {
                        ZStack(alignment: .bottom) {
                            photoContent()
                            PhotoLibraryPicker(selectedMode: $viewModel.selectedMode)
                                .opacity(viewModel.contentMode == .library ? 1 : 0)
                        }
                    }
                }
                .environment(\.editMode, $editMode)
                .onReceive(viewModel.selection.$editMode) {
                    editMode = $0
                }
            }
        }
        .sheet(isPresented: $viewModel.showFilter) {
            PhotoLibraryFilterView(viewModel: viewModel.filterViewModel,
                                   isPresented: $viewModel.showFilter,
                                   onFilterUpdate: onFilterUpdate)
        }
    }
    
    @ViewBuilder
    @available(iOS 15.0, *)
    private func content() -> some View {
        if viewModel.shouldShowPhotoLibraryPicker {
            photoContent()
                .safeAreaInset(edge: .bottom) {
                    if editMode.isEditing && viewModel.contentMode == .library {
                        EmptyView()
                    } else {
                        PhotoLibraryPicker(selectedMode: $viewModel.selectedMode)
                    }
                }
        } else {
            photoContent()
                .safeAreaInset(edge: .bottom) {
                    EmptyView().frame(height: 64)
                }
        }
    }
    
    @ViewBuilder
    private func photoContent() -> some View {
        ZStack {
            switch viewModel.selectedMode {
            case .year:
                PhotoLibraryYearView(
                    viewModel: PhotoLibraryYearViewModel(libraryViewModel: viewModel),
                    router: router
                )
            case .month:
                PhotoLibraryMonthView(
                    viewModel: PhotoLibraryMonthViewModel(libraryViewModel: viewModel),
                    router: router
                )
            case .day:
                PhotoLibraryDayView(
                    viewModel: PhotoLibraryDayViewModel(libraryViewModel: viewModel),
                    router: router
                )
            case .all:
                EmptyView()
            }
            
            PhotoLibraryModeAllView(viewModel: viewModel, router: router)
                .opacity(viewModel.selectedMode == .all ? 1.0 : 0.0)
                .zIndex(viewModel.selectedMode == .all ? 1.0 : -1.0)
        }
    }
}
