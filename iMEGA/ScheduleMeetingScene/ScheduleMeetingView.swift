import MEGAL10n
import SwiftUI

struct ScheduleMeetingView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Namespace var bottomViewID
    
    @State private var isBottomViewInFocus = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isWaitingRoomFeatureEnabled && viewModel.showWaitingRoomWarningBanner {
                WaitingRoomWarningBannerView(showBanner: $viewModel.showWaitingRoomWarningBanner) {
                    viewModel.waitingRoomWarningBannerDismissed = true
                }

            }
            ScrollViewReader { proxy in
                ScrollView {
                    ScheduleMeetingCreationNameView(viewModel: viewModel, appearFocused: viewModel.meetingName.isEmpty)
                    if viewModel.meetingNameTooLong {
                        ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.lenghtError)
                    }
                    ScheduleMeetingCreationPropertiesView(viewModel: viewModel)
                    ScheduleMeetingCreationInvitationView(viewModel: viewModel)
                    if viewModel.isWaitingRoomFeatureEnabled {
                        ScheduleMeetingCreationWaitingRoomView(waitingRoomEnabled: $viewModel.waitingRoomEnabled, shouldAllowEditingWaitingRoom: viewModel.shouldAllowEditingWaitingRoom)
                    }
                    ScheduleMeetingCreationOpenInviteView(viewModel: viewModel)
                    ScheduleMeetingCreationDescriptionView(viewModel: viewModel, isBottomViewInFocus: $isBottomViewInFocus)
                    
                    Spacer()
                        .frame(height: 0)
                        .id(bottomViewID)
                }
                .onChange(of: viewModel.meetingDescription) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onReceive(
                    NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardDidShowNotification)
                ) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .customScrollViewDismissKeyboard()
            }
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .onAppear {
            viewModel.updateRightBarButtonState()
        }
        .actionSheet(isPresented: $viewModel.showDiscardAlert) {
            ActionSheet(title: Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.title), buttons: discardChangesButtons())
        }
    }
    
    private func discardChangesButtons() -> [ActionSheet.Button] {
        return [
            ActionSheet.Button.default(Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.confirm)) {
                viewModel.discardChangesTap()
            },
            ActionSheet.Button.cancel(Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.cancel)) {
                viewModel.keepEditingTap()
            }
        ]
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard isBottomViewInFocus else { return }
        withAnimation {
            proxy.scrollTo(bottomViewID, anchor: .top)
        }
    }
}
