#import "ContactTableViewCell.h"

@import MEGAL10nObjc;

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface ContactTableViewCell () <ChatNotificationControlCellProtocol>
@end

#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import "NSString+MNZCategory.h"
@import MEGASDKRepo;

@implementation ContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.delegate = nil;
    [self.controlSwitch setOn:YES];
    
    self.avatarImageView.image = nil;
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = (self.subviews.count == 3); // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 100, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
            [self layoutIfNeeded];
        }];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.shareLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.permissionsLabel.textColor = [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
}

- (NSString *)userNameForUser:(MEGAUser *)user {
    NSString *userName;
    if (user.handle == MEGASdk.currentUserHandle.unsignedLongLongValue) {
        userName = [userName stringByAppendingString:[NSString stringWithFormat:@" (%@)", LocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")]];
    } else {
        userName = user.mnz_displayName;
    }
    
    return userName;
}

- (void)configureDefaultCellForUser:(MEGAUser *)user newUser:(BOOL)newUser {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:user];
    
    NSString *userName = [self userNameForUser:user];
    self.nameLabel.text = userName ? userName : user.email;
    
    MEGAChatStatus userStatus = [MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:user.handle];
    self.shareLabel.text = [NSString chatStatusString:userStatus];
    self.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:userStatus];
    if (userStatus < MEGAChatStatusOnline) {
        [MEGASdkManager.sharedMEGAChatSdk requestLastGreen:user.handle];
    }
    
    if (newUser) {
        self.contactNewView.hidden = NO;
        self.contactNewLabel.text = LocalizedString(@"New", @"Label shown inside an unseen notification");
        self.contactNewLabel.textColor = UIColor.whiteColor;
        self.contactNewLabelView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    } else {
        self.contactNewView.hidden = YES;
    }
}

- (void)configureCellForContactsModeFolderSharedWith:(MEGAUser *)user indexPath:(NSIndexPath *)indexPath {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:user];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.permissionsImageView.hidden = YES;
            self.avatarImageView.image = [UIImage imageNamed:@"inviteToChat"];
            self.nameLabel.text = LocalizedString(@"addContactButton", @"Button title to 'Add' the contact to your contacts list");
            self.shareLabel.hidden = YES;
        } else {
            NSString *userName = [self userNameForUser:user];
            if (userName) {
                self.nameLabel.text = userName;
                self.shareLabel.text = user.email;
                self.shareLabel.hidden = NO;
            } else {
                self.nameLabel.text = user.email;
                self.shareLabel.hidden = YES;
            }
        }
    } else if (indexPath.section == 1) {
        self.shareLabel.hidden = YES;
        self.permissionsImageView.image = [UIImage imageNamed:@"delete"];
        self.permissionsImageView.tintColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    }
}

- (void)configureCellForContactsModeChatStartConversation:(ContactsStartConversation)option {
    self.permissionsImageView.hidden = YES;
    switch (option) {
        case ContactsStartConversationNewGroupChat:
            self.nameLabel.text = LocalizedString(@"New Group Chat", @"Text button for init a group chat");
            self.avatarImageView.image = [UIImage imageNamed:@"createGroup"];
            break;
        case ContactsStartConversationNewMeeting:
            self.nameLabel.text = LocalizedString(@"meetings.create.newMeeting", @"Text button for init a Meeting.");
            self.avatarImageView.image = [UIImage imageNamed:@"newMeeting"];
            break;
        case ContactsStartConversationJoinMeeting:
            self.nameLabel.text = LocalizedString(@"meetings.link.loggedInUser.joinButtonText", @"Text button for joining a Meeting.");
            self.avatarImageView.image = [UIImage imageNamed:@"joinMeeting"];
            break;
    }
    self.shareLabel.hidden = YES;
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(notificationSwitchValueChanged:)]) {
        [self.delegate notificationSwitchValueChanged:sender];
    }
}

#pragma mark - ChatNotificationControlCellProtocol

- (UIImageView *)iconImageView {
    return self.avatarImageView;
}

@end
