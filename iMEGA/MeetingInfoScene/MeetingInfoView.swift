import MEGAL10n
import SwiftUI

struct MeetingInfoView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let spacing: CGFloat = 20
    }
    
    @ObservedObject var viewModel: MeetingInfoViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isWaitingRoomFeatureEnabled && viewModel.showWaitingRoomWarningBanner {
                WaitingRoomWarningBannerView(showBanner: $viewModel.showWaitingRoomWarningBanner) {
                    viewModel.waitingRoomWarningBannerDismissed = true
                }
            }
            ScrollView {
                VStack(spacing: Constants.spacing) {
                    MeetingInfoHeaderView()
                        .environmentObject(viewModel)
                    
                    if let chatRoomLinkViewModel = viewModel.chatRoomLinkViewModel, viewModel.isModerator {
                        ChatRoomLinkView(viewModel: chatRoomLinkViewModel)
                    }
                    
                    if viewModel.isUserInChat, let chatRoomNotificationsViewModel = viewModel.chatRoomNotificationsViewModel {
                        ChatRoomNotificationsView(viewModel: chatRoomNotificationsViewModel)
                    }
                    
                    if viewModel.isModerator {
                        if viewModel.isWaitingRoomFeatureEnabled {
                            MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: $viewModel.isWaitingRoomOn, shouldAllowEditingWaitingRoom: viewModel.shouldAllowEditingWaitingRoom)
                        }
                        
                        ToggleView(
                            image: Asset.Images.Meetings.Info.allowNonHostToAddParticipant.name,
                            text: Strings.Localizable.Meetings.AddContacts.AllowNonHost.message,
                            isOn: $viewModel.isAllowNonHostToAddParticipantsOn)
                        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                    }
                    
                    DisclosureView(
                        image: Asset.Images.Meetings.Info.sharedFilesInfo.name,
                        text: Strings.Localizable.Meetings.Info.sharedFiles) {
                            viewModel.sharedFilesViewTapped()
                        }
                        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                    
                    if viewModel.isModerator {
                        DisclosureView(
                            image: Asset.Images.Meetings.Info.manageChatHistory.name,
                            text: Strings.Localizable.Meetings.Info.manageMeetingHistory) {
                                viewModel.manageChatHistoryViewTapped()
                            }
                            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                        
                        KeyRotationView(
                            title: Strings.Localizable.Meetings.Info.KeyRotation.title,
                            rightDetail: Strings.Localizable.enabled,
                            footer: Strings.Localizable.Meetings.Info.KeyRotation.description,
                            isPublicChat: $viewModel.isPublicChat) {
                                viewModel.enableEncryptionKeyRotationViewTapped()
                            }
                    } else if let chatRoomLinkViewModel = viewModel.chatRoomLinkViewModel {
                        ChatRoomLinkNonHostView(viewModel: chatRoomLinkViewModel)
                    }
                    
                    if let chatRoomParticipantsListViewModel = viewModel.chatRoomParticipantsListViewModel {
                        ChatRoomParticipantsListView(viewModel: chatRoomParticipantsListViewModel)
                    }
                    
                    if case let description = viewModel.scheduledMeeting.description, !description.isEmpty {
                        MeetingDescriptionView(description: description)
                    }
                    
                    if viewModel.isUserInChat {
                        LeaveChatButtonView(text: viewModel.isChatPreview() ? Strings.Localizable.close : Strings.Localizable.Meetings.Info.leaveMeeting) {
                            viewModel.leaveGroupViewTapped()
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
    }
}
