#import "ChatRoomsViewController.h"
#import <Contacts/Contacts.h>
#import "UIScrollView+EmptyDataSet.h"
#import "UIApplication+MNZCategory.h"
#import "Helper.h"
#import "MEGAChatChangeGroupNameRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGALinkManager.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "MEGA-Swift.h"
#import "UITableView+MNZCategory.h"
#import "UIViewController+MNZCategory.h"
#import "ChatRoomCell.h"
#import "ChatSettingsTableViewController.h"
#import "ContactDetailsViewController.h"
#import "ContactsViewController.h"
#import "EmptyStateView.h"
#import "GroupChatDetailsViewController.h"
#import "TransfersWidgetViewController.h"
#import "NSArray+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatDelegate, UIScrollViewDelegate, MEGAChatCallDelegate, UISearchControllerDelegate, PushNotificationControlProtocol, AudioPlayerPresenterProtocol>

@property (weak, nonatomic) IBOutlet UIView *archivedChatEmptyState;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateTitle;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateCount;
@property (weak, nonatomic) IBOutlet UIStackView *contactsOnMegaEmptyStateView;
@property (weak, nonatomic) IBOutlet UILabel *contactsOnMegaEmptyStateTitle;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) MEGAChatListItemList *archivedChatListItemList;
@property (nonatomic, strong) NSMutableArray *chatListItemArray;
@property (nonatomic, strong) NSMutableArray *searchChatListItemArray;
@property (nonatomic, strong) NSMutableDictionary *chatIdIndexPathDictionary;
@property (nonatomic) NSMutableArray<MEGAUser *> *usersWithoutChatArray;
@property (nonatomic) NSMutableArray<MEGAUser *> *searchUsersWithoutChatArray;

@property (assign, nonatomic) BOOL isArchivedChatsRowVisible;
@property (assign, nonatomic) BOOL isScrollAtTop;

@property (weak, nonatomic) IBOutlet UIView *topBannerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBannerViewTopConstraint;
@property (weak, nonatomic) IBOutlet UILabel *topBannerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topBannerMicrophoneMutedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *topBannerCameraEnabledImageView;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (strong, nonatomic) MEGAChatRoom *chatRoomOnGoingCall;
@property (strong, nonatomic) ActionSheetViewController *optionsActionSheetVC;

@property (nonatomic, getter=isReconnecting) BOOL reconnecting;

@property (nonatomic) ChatNotificationControl *chatNotificationControl;
@property (strong, nonatomic) NSObject *enterMeetingLinkObject;

@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self customNavigationBarLabel];
    
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        [self configureContextMenuManager];
    }
    
    self.chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    self.chatListItemArray = [[NSMutableArray alloc] init];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    MEGAUserList *users = [[MEGASdkManager sharedMEGASdk] contacts];
    self.usersWithoutChatArray = [[NSMutableArray alloc] init];
    NSInteger count = users.size.integerValue;
    for (NSInteger i = 0; i < count; i++) {
        MEGAUser *user = [users userAtIndex:i];
        if (![[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle] && user.visibility == MEGAUserVisibilityVisible) {
            [self.usersWithoutChatArray addObject:user];
        }
    }
    self.addBarButtonItem.accessibilityLabel = LocalizedString(@"startConversation", @"start a chat/conversation");
    self.moreBarButtonItem.accessibilityLabel = LocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault:
            [self loadChatListItemListForSelectedChatType];
            self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            self.addBarButtonItem.enabled = [MEGAReachabilityManager isReachable] && MEGASdkManager.sharedMEGASdk.businessStatus != BusinessStatusExpired;
            break;
            
        case ChatRoomsTypeArchived:
            self.chatOrMeetingSelectorView.hidden = YES;
            self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            self.navigationItem.rightBarButtonItems = @[];
            break;
    }
    
    if (self.chatListItemList.size) {
        [self reorderList];
        
        [self updateChatIdIndexPathDictionary];
        [self configureSearchController];
    }
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        [self configureNavigationBarButtons];
    }
    
    self.tabBarController.tabBar.hidden = NO;
    [self customNavigationBarLabel];

    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    if ([[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitOnlineSession) {
        [self reloadData];
    }
    
    self.chatRoomOnGoingCall = nil;
    MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
    if ((chatRoomIDsWithCallInProgress.size > 0) && MEGAReachabilityManager.isReachable) {
        self.chatRoomOnGoingCall = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:[chatRoomIDsWithCallInProgress megaHandleAtIndex:0]];
        
        if (self.chatRoomOnGoingCall) {
            if (self.topBannerViewTopConstraint.constant == -44) {
                [self showTopBanner];
            }
            
            MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:self.chatRoomOnGoingCall.chatId];
            [self configureTopBannerForInProgressCall:call];
        } else {
            if (self.topBannerViewTopConstraint.constant == 0) {
                [self hideTopBanner];
            }
        }
    } else {
        [self hideTopBanner];
    }
    
    self.globalDNDNotificationControl = [GlobalDNDNotificationControl.alloc initWithDelegate:self];
    self.chatNotificationControl = [ChatNotificationControl.alloc initWithDelegate:self];
    
    [self refreshMyAvatar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self askNotificationPermissionsIfNeeded];
    self.navigationController.toolbarHidden = true;
    
    [AudioPlayerManager.shared addDelegate:self];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.chatRoomsType == ChatRoomsTypeArchived) {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
        [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    }
    
    [AudioPlayerManager.shared removeDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (MEGAReachabilityManager.isReachable) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"IsChatEnabled"]) {
            if (MEGASdkManager.sharedMEGAChatSdk.initState == MEGAChatInitWaitingNewSession || MEGASdkManager.sharedMEGAChatSdk.initState == MEGAChatInitNoCache) {
                return [UIImageView.alloc initWithImage:[UIImage imageNamed:@"chatListLoading"]];
            }
        }
    }
    
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
            
    if (self.chatTypeSelected == MEGAChatTypeMeeting) {
        [self setEmptyViewButtonWithMeetingsOptionsWithButton:emptyStateView.button];
    } else {
        [self setEmptyViewButtonWithChatOptionsWithButton:emptyStateView.button];
    }
    
    return emptyStateView;
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = YES;
        self.archivedChatListItemList = MEGASdkManager.sharedMEGAChatSdk.archivedChatListItems;
        if (self.archivedChatListItemList.size) {
            self.archivedChatEmptyStateTitle.text = LocalizedString(@"archivedChats", @"Title of archived chats button");
            self.archivedChatEmptyStateCount.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
            self.archivedChatEmptyState.hidden = NO;
        }
        if (self.chatRoomsType == ChatRoomsTypeDefault) {
            self.contactsOnMegaEmptyStateTitle.text = LocalizedString(@"Invite contact now", @"Text emncouraging the user to add contacts in MEGA");
            self.contactsOnMegaEmptyStateView.hidden = NO;
        }
    }
}

- (void)emptyDataSetWillDisappear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = NO;
        if (!self.archivedChatEmptyState.hidden) {
            self.archivedChatEmptyState.hidden = YES;
        }
        if (!self.contactsOnMegaEmptyStateView.hidden) {
            self.contactsOnMegaEmptyStateView.hidden = YES;
        }
    }
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                if (self.chatSelectorButton.isSelected) {
                    text = LocalizedString(@"chat.chats.emptyState.title", @"Ttile for empty chats tab");
                } else {
                    text = LocalizedString(@"chat.meetings.emptyState.title", @"Ttile for empty meetings tab ");

                }
                break;
                
            case ChatRoomsTypeArchived:
                text = LocalizedString(@"noArchivedChats", @"Title of empty state view for archived chats.");
                break;
        }
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";

    if (self.searchController.isActive) {
        text = @"";
    } else {
        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                if (self.chatSelectorButton.isSelected) {
                    text = LocalizedString(@"chat.chats.emptyState.description", @"Description for empty chats tab");
                } else {
                    text = LocalizedString(@"chat.meetings.emptyState.description", @"Description for empty meetings tab");
                }
                break;
                
            case ChatRoomsTypeArchived:
                break;
        }
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
                return nil;
            } else {
                switch (self.chatRoomsType) {
                    case ChatRoomsTypeDefault:
                        if (self.chatSelectorButton.isSelected) {
                            return [UIImage imageNamed:@"chatEmptyState"];
                        } else {
                            return [UIImage imageNamed:@"meetingEmptyState"];
                        }
                    
                    case ChatRoomsTypeArchived:
                        return [UIImage imageNamed:@"chatsArchivedEmptyState"];
                }
            }
        }
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.searchController.isActive) {
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault:
                    if (self.chatSelectorButton.isSelected) {
                        text = LocalizedString(@"chat.chats.emptyState.button.title", @"Text button for empty chats tab");
                    } else {
                        text = LocalizedString(@"chat.meetings.emptyState.button.title", @"Text button for empty meetings tab");
                    }
                    break;
                case ChatRoomsTypeArchived:
                    return nil;
            }
        }
    }
    
    return text;
}

#pragma mark - Public

- (void)openChatRoomWithID:(uint64_t)chatID {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        UIViewController *currentVC = self.navigationController.viewControllers[1];
        if ([currentVC isKindOfClass:ChatViewController.class]) {
            ChatViewController *currentChatViewController= (ChatViewController *)currentVC;
            if (currentChatViewController.chatRoom.chatId == chatID) {
                if (viewControllers.count != 2) {
                    [self.navigationController popToViewController:currentChatViewController animated:YES];
                }
                return;
            } else {
                [currentChatViewController closeChatRoom];
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        }
    }

    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatID];
    if (chatRoom != nil) {
        ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
        [self.navigationController pushViewController:chatViewController animated:YES];

    }
}


- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        UIViewController *currentVC = self.navigationController.viewControllers[1];
        if ([currentVC isKindOfClass:ChatViewController.class]) {
            ChatViewController *currentMessagesVC = (ChatViewController *)currentVC;
            if (currentMessagesVC.publicChatWithLinkCreated && [currentMessagesVC.publicChatLink isEqual:publicLink] ) {
                if (viewControllers.count != 2) {
                    [self.navigationController popToViewController:currentMessagesVC animated:YES];
                }
                return;
            } else {
                [currentMessagesVC closeChatRoom];
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        }
    }

    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatID];
    
    if (chatRoom != nil) {
        ChatViewController *messagesVC = [ChatViewController.alloc initWithChatRoom:chatRoom];
        messagesVC.publicChatWithLinkCreated = YES;
        messagesVC.publicChatLink = [NSURL URLWithString:publicLink];
        [self.navigationController pushViewController:messagesVC animated:YES];
    }
}

- (void)showStartConversation {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = ContactsModeChatStartConversation;
    
    switch (self.chatTypeSelected ) {
    case MEGAChatTypeMeeting:
        contactsVC.chatOptionType = ChatOptionTypeMeeting;
        break;
        
    case MEGAChatTypeNonMeeting:
        contactsVC.chatOptionType = ChatOptionTypeNonMeeting;
        break;
        
    default:
        break;
    }
    
    [self blockCompletionsForCreateChatInContacts:contactsVC];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    self.navigationController.view.backgroundColor = UIColor.mnz_background;

    self.archivedChatEmptyStateCount.textColor = UIColor.mnz_secondaryLabel;
    
    self.topBannerView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    self.topBannerLabel.textColor = UIColor.whiteColor;
    self.chatOrMeetingSelectorView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable] && MEGASdkManager.sharedMEGASdk.businessStatus != BusinessStatusExpired;
    self.addBarButtonItem.enabled = boolValue;
    
    [self customNavigationBarLabel];
    [self.tableView reloadData];
}

- (MEGAChatListItem *)chatListItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = nil;
    if (indexPath) {
        if (self.searchController.isActive) {
            chatListItem = [self.searchChatListItemArray objectOrNilAtIndex:indexPath.row];
        } else {
            chatListItem = [self.chatListItemArray objectOrNilAtIndex:indexPath.row];
        }
    }
    return chatListItem;
}

- (void)deleteRowByChatId:(uint64_t)chatId {
    BOOL isUserContactsSectionVisible = [self isUserContactsSectionVisible];

    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray removeObjectAtIndex:indexPath.row];
        for (MEGAChatListItem *chatListItem in [self.chatListItemArray mutableCopy]) {
            if (chatListItem.chatId == chatId) {
                [self.chatListItemArray removeObject:chatListItem];
            }
        }
    } else {
        [self.chatListItemArray removeObjectAtIndex:indexPath.row];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if ([self numberOfChatRooms] == 0  && self.chatRoomsType == ChatRoomsTypeDefault) {
        if (self.isArchivedChatsRowVisible) {
            self.isScrollAtTop = NO;
            self.isArchivedChatsRowVisible = NO;
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        if (isUserContactsSectionVisible) {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    [self.tableView endUpdates];
    [self updateChatIdIndexPathDictionary];
}

- (void)insertRowByChatListItem:(MEGAChatListItem *)item {
    BOOL addingFirstChat = [self numberOfChatRooms] == 0;
    
    NSInteger section = self.chatRoomsType == ChatRoomsTypeDefault ? 2 : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray insertObject:item atIndex:indexPath.row];
    } else {
        [self.chatListItemArray insertObject:item atIndex:indexPath.row];
    }
    [self updateChatIdIndexPathDictionary];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if (addingFirstChat && [self isUserContactsSectionVisible]) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        [self configureSearchController];
    }
    [self.tableView endUpdates];
}

- (void)moveRowByChatListItem:(MEGAChatListItem *)item {
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
    NSIndexPath *newIndexPath;
    NSMutableArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *chatListItem in tempArray) {
        if ([item.lastMessageDate compare:chatListItem.lastMessageDate]>=NSOrderedSame) {
            newIndexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatListItem.chatId)];
            [tempArray removeObjectAtIndex:indexPath.row];
            [tempArray insertObject:item atIndex:newIndexPath.row];
            break;
        }
    }

    [self updateChatIdIndexPathDictionary];
    
    if (newIndexPath) {
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

- (void)updateChatIdIndexPathDictionary {
    [self.chatIdIndexPathDictionary removeAllObjects];
    NSInteger i = 0;
    NSInteger section = self.chatRoomsType == ChatRoomsTypeDefault ? 2 : 0;

    NSArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *item in tempArray) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [self.chatIdIndexPathDictionary setObject:indexPath forKey:@(item.chatId)];
        i++;
    }
}

- (void)presentGroupOrContactDetailsForChatListItem:(MEGAChatListItem *)chatListItem {
    if (chatListItem.isGroup) {
        if ([MEGALinkManager.joiningOrLeavingChatBase64Handles containsObject:[MEGASdk base64HandleForUserHandle:chatListItem.chatId]]) {
            return;
        }
        GroupChatDetailsViewController *groupChatDetailsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupChatDetailsViewControllerID"];
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        groupChatDetailsVC.chatRoom = chatRoom;
        [self.navigationController pushViewController:groupChatDetailsVC animated:YES];
    } else {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        NSString *peerEmail     = [[MEGASdkManager sharedMEGAChatSdk] contactEmailByHandle:[chatRoom peerHandleAtIndex:0]];
        uint64_t peerHandle     = [chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.userEmail          = peerEmail;
        contactDetailsVC.userHandle         = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

- (void)loadChatListItemListForSelectedChatType {
    if (self.chatTypeSelected == MEGAChatTypeMeeting) {
        self.chatListItemList = [MEGAChatSdk.shared chatListItemsByMask:MEGAChatListMaskMeetingOrNonMeeting | MEGAChatListMaskArchivedOrNonArchived
                                                                 filter:MEGAChatListFilterMeeting | MEGAChatListFilterNonArchived];
    } else {
        self.chatListItemList = [MEGAChatSdk.shared chatListItemsByMask:MEGAChatListMaskMeetingOrNonMeeting | MEGAChatListMaskArchivedOrNonArchived
                                                                 filter:MEGAChatListFilterNonMeeting | MEGAChatListFilterNonArchived];
    }
}

- (void)reloadData {
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        [self loadChatListItemListForSelectedChatType];
    } else {
        self.chatListItemList = [MEGAChatSdk.shared archivedChatListItems];
    }
    self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
    [self reorderList];
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

- (void)reorderList {
    [self.chatListItemArray removeAllObjects];
    
    for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
        MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
        [self.chatListItemArray addObject:chatListItem];
    }
    self.chatListItemArray = [[self.chatListItemArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first  = [(MEGAChatListItem *)a lastMessageDate];
        NSDate *second = [(MEGAChatListItem *)b lastMessageDate];
        
        if (!first) {
            first = [NSDate dateWithTimeIntervalSince1970:0];
        }
        if (!second) {
            second = [NSDate dateWithTimeIntervalSince1970:0];
        }
        
        return [second compare:first];
    }] mutableCopy];
}

- (NSInteger)numberOfChatRooms {
    return self.searchController.isActive ? self.searchChatListItemArray.count : self.chatListItemArray.count;
}

- (void)showChatRoomAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    MEGAChatRoom *chatRoom         = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    if (chatRoom != nil) {
        ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
        [self.navigationController pushViewController:chatViewController animated:YES];
    }
}

- (void)createChatRoomWithUserAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.searchUsersWithoutChatArray objectOrNilAtIndex:indexPath.row];
    if (user == nil) { return; }
    
    [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
        ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
        [self.navigationController pushViewController:chatViewController animated:YES];
    }];
    
    [self.searchUsersWithoutChatArray removeObject:user];
    [self.usersWithoutChatArray removeObject:user];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (UITableViewCell *)archivedChatRoomCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = (ChatRoomCell *)[self chatRoomCellForIndexPath:indexPath];
    [cell configureCellForArchivedChat];
    return cell;
}

- (UITableViewCell *)chatRoomCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    BOOL muted = [self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId];
    [cell configureCellForChatListItem:chatListItem isMuted:muted];
    return cell;
}

- (UITableViewCell *)userCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    MEGAUser *user = [self.searchUsersWithoutChatArray objectOrNilAtIndex:indexPath.row];
    if (user == nil) { return cell; }
    [cell configureCellForUser:user];
    return cell;
}

- (UITableViewCell *)contactsOnMegaCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"contactsOnMegaCell" forIndexPath:indexPath];
    cell.chatTitle.text = LocalizedString(@"Invite contact now", @"Text emncouraging the user to add contacts in MEGA");
    return cell;
}

- (UITableViewCell *)archivedChatsCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"archivedChatsCell" forIndexPath:indexPath];
    cell.avatarView.avatarImageView.image = [UIImage imageNamed:@"archiveChat"];
    cell.avatarView.avatarImageView.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    [cell.avatarView configureWithMode:MegaAvatarViewModeSingle];
    cell.chatTitle.text = LocalizedString(@"archivedChats", @"Title of archived chats button");
    cell.chatLastMessage.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
    return cell;
}

- (BOOL)isUserContactsSectionVisible {
    return [self numberOfChatRooms] > 0;
}

- (void)configureSearchController {
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
    });
}

- (void)showOptionsForChatAtIndexPath:(NSIndexPath *)indexPath {

    [self.tableView setEditing:NO animated:YES];
    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    NSMutableArray *actions = NSMutableArray.new;
  
    if (chatListItem.unreadCount != 0) {
        ActionSheetAction *markAsReadAction = [ActionSheetAction.alloc initWithTitle:LocalizedString(@"Mark as Read", @"A button label. The button allows the user to mark a conversation as read.)") detail:nil accessoryView:nil image:[UIImage imageNamed:@"markUnread_menu"] style:UIAlertActionStyleDefault actionHandler:^{
            [MEGASdkManager.sharedMEGAChatSdk setMessageSeenForChat:chatListItem.chatId messageId:chatListItem.lastMessageId];
        }];
        [actions addObject:markAsReadAction];
    }
    
    if ([self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId]) {
        ActionSheetAction *unmuteAction = [ActionSheetAction.alloc initWithTitle:LocalizedString(@"unmute", @"A button label. The button allows the user to unmute a conversation") detail:nil accessoryView:nil image:[UIImage imageNamed:@"mutedChat_menu"] style:UIAlertActionStyleDefault actionHandler:^{
            [self.chatNotificationControl turnOffDNDWithChatId:chatListItem.chatId];
        }];
        [actions addObject:unmuteAction];
    } else {
        ActionSheetAction *muteAction = [ActionSheetAction.alloc initWithTitle:LocalizedString(@"mute", @"A button label. The button allows the user to mute a conversation") detail:nil accessoryView:nil image:[UIImage imageNamed:@"mutedChat_menu"] style:UIAlertActionStyleDefault actionHandler:^{
            [self.chatNotificationControl turnOnDNDWithChatId:chatListItem.chatId isChatTypeMeeting:[self isChatTypeMeeting] sender:[self.tableView cellForRowAtIndexPath:indexPath]];
        }];
        [actions addObject:muteAction];
    }
    
    ActionSheetAction *infoAction = [ActionSheetAction.alloc initWithTitle:LocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context.") detail:nil accessoryView:nil image:[UIImage imageNamed:@"info"] style:UIAlertActionStyleDefault actionHandler:^{
        [self presentGroupOrContactDetailsForChatListItem:chatListItem];
    }];
    [actions addObject:infoAction];

    ActionSheetAction *archiveChatAction = [ActionSheetAction.alloc initWithTitle:LocalizedString(@"archiveChat", @"Title of button to archive chats.)") detail:nil accessoryView:nil image:[UIImage imageNamed:@"archiveChat_menu"] style:UIAlertActionStyleDefault actionHandler:^{
        [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:YES];
    }];
    [actions addObject:archiveChatAction];

    ActionSheetViewController *actionSheetVC = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:nil];
    
    [self presentViewController:actionSheetVC animated:YES completion:nil];
}

- (BOOL)isChatTypeMeeting {
    return self.chatTypeSelected == MEGAChatTypeMeeting;
}

#pragma mark - TopBannerButton

- (void)showTopBanner {
    if (self.topBannerView.hidden) {
        self.topBannerView.hidden = NO;
        self.topBannerViewTopConstraint.constant = 44;
        [self.tableView setContentInset:UIEdgeInsetsMake(CGRectGetHeight(self.topBannerView.frame), 0, 0, 0)];
        [self.view layoutIfNeeded];
    }
}

- (void)hideTopBanner {
    if (!self.topBannerView.hidden) {
        [UIView animateWithDuration:.5f animations:^ {
            self.topBannerViewTopConstraint.constant = 0;
            self.tableView.contentInset = UIEdgeInsetsZero;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.topBannerView.hidden = YES;
        }];
    }
    
    [self.timer invalidate];
}

- (void)initTimerForCall:(MEGAChatCall *)call {
    self.initDuration = call.duration;
    self.baseDate = [NSDate date];
    if (!self.timer.isValid) {
        [self updateDuration];
        self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    self.reconnecting = NO;
}
- (void)updateDuration {
    if (!self.isReconnecting) {
        NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
        NSString *title = [NSString stringWithFormat:LocalizedString(@"chat.callInProgress.tapToReturnToCall", @"Message shown in a chat room for a call in progress displaying the duration of the call"), [NSString mnz_stringFromTimeInterval:interval]];
        self.topBannerLabel.text = title;
        
        [self manageCallIndicators];
    }
}

- (void)manageCallIndicators {
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:self.chatRoomOnGoingCall.chatId];

    self.topBannerMicrophoneMutedImageView.hidden = call.hasLocalAudio;
    self.topBannerCameraEnabledImageView.hidden = !call.hasLocalVideo;

    if (!call.hasLocalAudio || call.hasLocalVideo) {
        self.topBannerLabel.text = [self.topBannerLabel.text stringByAppendingString:@" •"];
    }
}

- (void)configureTopBannerForInProgressCall:(MEGAChatCall *)call {
    if (self.isReconnecting) {
        self.topBannerLabel.text = LocalizedString(@"You are back!", @"Title shown when the user reconnect in a call.");
        self.topBannerView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
        self.topBannerMicrophoneMutedImageView.hidden = YES;
        self.topBannerCameraEnabledImageView.hidden = YES;
    }
    [self initTimerForCall:call];
}

#pragma mark - IBActions

- (IBAction)joinActiveCall:(id)sender {
    DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
    
    [handler audioPermissionWithModal:YES incomingCall:NO completion:^(BOOL granted) {
        if (granted) {
            [self.timer invalidate];
            [self joinActiveCallWithChatRoom:self.chatRoomOnGoingCall];
        } else {
            [handler alertAudioPermissionWithIncomingCall:NO];
        }
    }];
}

- (IBAction)openArchivedChats:(id)sender {
    ChatRoomsViewController *archivedChatRooms = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatRoomsViewControllerID"];
    [self.navigationController pushViewController:archivedChatRooms animated:YES];
    archivedChatRooms.chatRoomsType = ChatRoomsTypeArchived;
}

- (void)blockCompletionsForCreateChatInContacts:(ContactsViewController *)contactsVC {
    
    contactsVC.userSelected = ^void(NSArray *users) {
        if (users.count == 1) {
            MEGAUser *user = users.firstObject;
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
            if (chatRoom) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                    [self.navigationController pushViewController:chatViewController animated:YES];
                });
            } else {
                [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                    ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                    [self.navigationController pushViewController:chatViewController animated:YES];
                }];
            }
        }
    };
    
    contactsVC.chatSelected = ^(uint64_t chatId) {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId];
        if (chatRoom != nil) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                [self.navigationController pushViewController:chatViewController animated:YES];
            });
        }
    };
    
    contactsVC.createGroupChat = ^void(NSArray *users,
                                       NSString *groupName,
                                       BOOL keyRotation,
                                       BOOL getChatLink,
                                       BOOL allowNonHostToAddParticipants) {
        if (keyRotation) {
            [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUsersArray:users
                                                                         title:groupName
                                                 allowNonHostToAddParticipants:allowNonHostToAddParticipants
                                                                    completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                    [self.navigationController pushViewController:chatViewController animated:YES];
                });
            }];
        } else {
            MEGAChatGenericRequestDelegate *createChatGroupRequestDelegate = [MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:request.chatHandle];
                if (chatRoom != nil) {
                    if (getChatLink) {
                        MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                            if (!error.type) {
                                ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                                chatViewController.publicChatWithLinkCreated = YES;
                                chatViewController.publicChatLink = [NSURL URLWithString:request.text];
                                [self.navigationController pushViewController:chatViewController animated:YES];
                            }
                        }];
                        [MEGASdkManager.sharedMEGAChatSdk createChatLink:chatRoom.chatId delegate:delegate];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
                            [self.navigationController pushViewController:chatViewController animated:YES];
                        });
                    }
                }
            }];
            
            [MEGASdkManager.sharedMEGAChatSdk createPublicChatWithPeers:[MEGAChatPeerList mnz_standardPrivilegePeerListWithUsersArray:users]
                                                                  title:groupName
                                                           speakRequest:false
                                                            waitingRoom:false
                                                              openInvite:allowNonHostToAddParticipants
                                                               delegate:createChatGroupRequestDelegate];
        }
    };
}

- (IBAction)openContactsOnMega:(id)sender {
    if ([self hasAuthorizedContacts]) {
        InviteContactViewController *inviteContacts = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
        [self.navigationController pushViewController:inviteContacts animated:YES];
    }
}

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    [self showStartConversation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault:
            return 4;
            
        case ChatRoomsTypeArchived:
            return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.chatRoomsType == ChatRoomsTypeArchived) {
        return [self numberOfChatRooms];
    }
    
    switch (section) {
        case 0:
            if (self.isArchivedChatsRowVisible > 0 && !self.searchController.isActive) {
                return 1;
            } else {
                return 0;
            }
        
        case 1:
            if ([self numberOfChatRooms] > 0 && !self.searchController.isActive) {
                return 1;
            } else {
                return 0;
            }
            
        case 2:
            return [self numberOfChatRooms];

        case 3:
            return self.searchController.isActive ? self.searchUsersWithoutChatArray.count : 0;
            
        default:
            return 0;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
        MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        
        if ((self.chatRoomsType == ChatRoomsTypeDefault && indexPath.section < 2) || chatRoom == nil) {
            return nil;
        }

        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            ChatViewController *chatViewController = [ChatViewController.alloc initWithChatRoom:chatRoom];
            chatViewController.previewMode = YES;
            return chatViewController;
            
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            NSMutableArray *menus = [NSMutableArray new];
            
            if (chatRoom.unreadCount != 0) {
                UIAction *markAsReadAction = [UIAction actionWithTitle:LocalizedString(@"Mark as Read",@"A button label. The button allows the user to mark a conversation as read.") image:[UIImage imageNamed:@"markUnread_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [MEGASdkManager.sharedMEGAChatSdk setMessageSeenForChat:chatListItem.chatId messageId:chatListItem.lastMessageId];
                }];
                [menus addObject:markAsReadAction];
            }
            
            BOOL muted = [self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId];
            if (muted) {
                UIAction *unmuteAction = [UIAction actionWithTitle:LocalizedString(@"unmute", @"A button label. The button allows the user to unmute a conversation") image:[UIImage imageNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOffDNDWithChatId:chatListItem.chatId];
                }];
                [menus addObject:unmuteAction];
            } else {
                UIAction *muteAction = [UIAction actionWithTitle:LocalizedString(@"mute", @"A button label. The button allows the user to mute a conversation") image:[UIImage imageNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOnDNDWithChatId:chatListItem.chatId isChatTypeMeeting:[self isChatTypeMeeting] sender:[tableView cellForRowAtIndexPath:indexPath]];
                }];
                [menus addObject:muteAction];
            }

            UIAction *infoAction = [UIAction actionWithTitle:LocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context. ") image:[UIImage imageNamed:@"info"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            [menus addObject:infoAction];
            
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault: {
                    UIAction *archiveChatAction = [UIAction actionWithTitle:LocalizedString(@"archiveChat", @"Title of button to archive chats.") image:[UIImage imageNamed:@"archiveChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:YES];
                    }];
                    [menus addObject:archiveChatAction];
                    break;
                }
                case ChatRoomsTypeArchived:{
                    UIAction *archiveChatAction = [UIAction actionWithTitle:LocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") image:[UIImage imageNamed:@"unArchiveChat"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:NO];
                    }];
                    [menus addObject:archiveChatAction];
                    break;
                }
            }
            return [UIMenu menuWithTitle:@"" children:menus];
        }];
        return configuration;
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    ChatViewController *previewViewController = (ChatViewController *)animator.previewViewController;
    [animator addCompletion:^{
        [self.navigationController pushViewController:previewViewController animated:NO];
        previewViewController.previewMode = NO;
        [previewViewController update];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 0) {
                return [self archivedChatsCellForIndexPath:indexPath];
            } else if (indexPath.section == 1) {
                return [self contactsOnMegaCellForIndexPath:indexPath];
            } else if (indexPath.section == 2) {
                return [self chatRoomCellForIndexPath:indexPath];
            } else if (indexPath.section == 3) {
                return [self userCellForIndexPath:indexPath];
            }
        }
            
        case ChatRoomsTypeArchived:
            return [self archivedChatRoomCellForIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 0) {
                [self openArchivedChats:self];
            } else if (indexPath.section == 1) {
                [self openContactsOnMega:self];
            } else if (indexPath.section == 2) {
                [self showChatRoomAtIndexPath:indexPath];
            } else if (indexPath.section == 3) {
                [self createChatRoomWithUserAtIndexPath:indexPath];
            }
            break;
        }
            
        case ChatRoomsTypeArchived: {
            [self showChatRoomAtIndexPath:indexPath];
            break;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 2) {
                return YES;
            } else {
                return NO;
            }
        }
            
        case ChatRoomsTypeArchived: {
            return YES;
        }
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];

    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            UIContextualAction *archiveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:YES];
            }];
            archiveAction.image = [[UIImage imageNamed:@"archiveChat"] imageWithTintColor:UIColor.whiteColor];
            archiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            UIContextualAction *infoAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [self showOptionsForChatAtIndexPath:indexPath];
            }];
            infoAction.image = [[UIImage imageNamed:@"moreList"] imageWithTintColor:UIColor.whiteColor];
            infoAction.backgroundColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[archiveAction, infoAction]];
        }
            
        case ChatRoomsTypeArchived: {
            UIContextualAction *unarchiveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:NO];
            }];
            unarchiveAction.image = [UIImage imageNamed:@"unArchiveChat"];
            unarchiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[unarchiveAction]];
        }
    }
}

#pragma mark - UIScrolViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.chatRoomsType == ChatRoomsTypeDefault && !self.searchController.isActive) {
        if (scrollView.contentOffset.y > 0 && self.isArchivedChatsRowVisible) {
            self.isScrollAtTop = NO;
            self.isArchivedChatsRowVisible = NO;
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
        if (self.isScrollAtTop && scrollView.contentOffset.y < 0 && !self.isArchivedChatsRowVisible && self.archivedChatListItemList.size != 0 && !self.searchController.active) {
            self.isArchivedChatsRowVisible = YES;
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {      // called when scroll view grinds to a halt
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        self.isScrollAtTop = scrollView.contentOffset.y > 0 ? NO : YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        if (scrollView.contentOffset.y > 0) {
            self.isScrollAtTop = NO;
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchChatListItemArray = nil;
    self.searchUsersWithoutChatArray = nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchChatListItemArray = self.chatListItemArray;
            self.searchUsersWithoutChatArray = self.usersWithoutChatArray;
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.searchString contains[c] %@", searchString];
            self.searchChatListItemArray = [[self.chatListItemArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];

            NSPredicate *fullnamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            NSPredicate *nicknamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_nickname contains[c] %@", searchString];
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF.email contains[c] %@", searchString];
            NSPredicate *resultPredicateForUsers = [NSCompoundPredicate orPredicateWithSubpredicates:@[fullnamePredicate, nicknamePredicate, emailPredicate]];
            self.searchUsersWithoutChatArray = [[self.usersWithoutChatArray filteredArrayUsingPredicate:resultPredicateForUsers] mutableCopy];
        }
    }
    
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    
    // New chat 1on1 or group
    if (item.changes == 0) {
        [self insertRowByChatListItem:item];
    } else {
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
        
        if (!indexPath && [item hasChangedForType:MEGAChatListItemChangeTypeArchived]) {
            [self insertRowByChatListItem:item];
            self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            if (self.isArchivedChatsRowVisible) {
                
                if ([self.archivedChatListItemList size] == 0) {
                    self.isArchivedChatsRowVisible = NO;
                }
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }
            return;
        }
        
        if (indexPath && self.chatListItemArray.count > 0) {
            if (self.searchController.isActive) {
                [self.searchChatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
            } else {
                [self.chatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
            }
            ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            switch (item.changes) {
                case MEGAChatListItemChangeTypeOwnPrivilege:
                    break;
                    
                case MEGAChatListItemChangeTypeUnreadCount:
                    [cell updateUnreadCountChange:item.unreadCount];
                    break;
                    
                case MEGAChatListItemChangeTypeTitle:
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                    break;
                    
                case MEGAChatListItemChangeTypeClosed:
                case MEGAChatListItemChangeTypePreviewClosed:
                    [self deleteRowByChatId:item.chatId];
                    break;
                    
                case MEGAChatListItemChangeTypeLastMsg:
                case MEGAChatListItemChangeTypeLastTs:
                case MEGAChatListItemChangeTypeParticipants:
                    [cell updateLastMessageForChatListItem:item];
                    break;
                    
                case MEGAChatListItemChangeTypeArchived:
                    [self deleteRowByChatId:item.chatId];
                    if (self.chatRoomsType == ChatRoomsTypeDefault) {
                         self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                    } else {
                         self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                    }
                    if (self.isArchivedChatsRowVisible) {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    if (!self.archivedChatEmptyState.hidden) {
                        self.archivedChatEmptyStateCount.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
                    }
                    if (self.archivedChatListItemList.size == 0) {
                        self.archivedChatEmptyState.hidden = YES;
                    }
                    if (self.chatListItemArray.count == 0) {
                        self.navigationItem.searchController = nil;
                    }
                    break;
                    
                default:
                    break;
            }
        }
        
        if (item.changes == MEGAChatListItemChangeTypeLastTs) {
            if ([indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]] != NSOrderedSame) {
                [self moveRowByChatListItem:item];
            }
        }
    }
}

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }
    
    if (userHandle == api.myUserHandle) {
        [self customNavigationBarLabel];
        [self refreshContextMenuBarButton];
    } else {
        uint64_t chatId = [api chatIdByUserHandle:userHandle];
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:userHandle]];
        }
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (chatId == MEGAInvalidHandle && newState == MEGAChatConnectionOnline) {
        // Now it's safe to trigger a reordering of the list:
        [self reloadData];
    }
    [self customNavigationBarLabel];
}

- (void)updateCallStatus:(MEGAChatCall *)call {
    if (!self.chatRoomOnGoingCall) {
        self.chatRoomOnGoingCall = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
    }
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
    if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self showTopBanner];
    [self configureTopBannerForInProgressCall:call];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);

    switch (call.status) {
        case MEGAChatCallStatusInProgress:
            [self updateCallStatus:call];
            break;
            
        case MEGAChatCallStatusConnecting:
            self.reconnecting = YES;
            self.topBannerLabel.text = LocalizedString(@"Reconnecting...", @"Title shown when the user lost the connection in a call, and the app will try to reconnect the user again.");
            self.topBannerView.backgroundColor = UIColor.systemOrangeColor;
            self.topBannerMicrophoneMutedImageView.hidden = YES;
            self.topBannerCameraEnabledImageView.hidden = YES;
            break;
            
        case MEGAChatCallStatusDestroyed:
        case MEGAChatCallStatusTerminatingUserParticipation:
        case MEGAChatCallStatusUserNoPresent: {
            self.chatRoomOnGoingCall = nil;
            NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self hideTopBanner];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - AudioPlayer

- (void)updateContentView:(CGFloat)height {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

@end
