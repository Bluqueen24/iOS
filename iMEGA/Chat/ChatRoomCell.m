#import "ChatRoomCell.h"

#import "UIImage+GKContact.h"

#import "MEGAChatListItem.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGAUser+MNZCategory.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAReachabilityManager.h"

@interface ChatRoomCell ()

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (strong, nonatomic) NSDate *twoDaysAgo;
@property (strong, nonatomic) MEGAChatListItem *chatListItem;

@end

@implementation ChatRoomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.chatTitle.adjustsFontForContentSizeCategory = YES;
    self.chatLastMessage.adjustsFontForContentSizeCategory = YES;
    self.chatLastTime.adjustsFontForContentSizeCategory = YES;
    self.unreadCount.adjustsFontForContentSizeCategory = YES;
    self.twoDaysAgo = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:-2 toDate:NSDate.date options:0];
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.avatarView.avatarImageView.image = nil;
    self.avatarView.firstPeerAvatarImageView.image = nil;
    self.avatarView.secondPeerAvatarImageView.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.chatLastMessage.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.chatLastTime.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    BOOL chatRoomsTypeArchived = [self.unreadCount.text isEqualToString:NSLocalizedString(@"archived", @"Title of flag of archived chats.").localizedUppercaseString];
    self.unreadView.backgroundColor = chatRoomsTypeArchived ? [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection] : [UIColor mnz_redForTraitCollection:self.traitCollection];
    self.unreadCount.textColor = UIColor.whiteColor;
    
    self.onCallDuration.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

- (void)manageUnreadMessages:(NSInteger)unreadCount {
    if (unreadCount != 0) {
        self.chatLastMessage.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] fontWithWeight:UIFontWeightMedium];
        self.chatLastMessage.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
        
        self.chatLastTime.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2] fontWithWeight:UIFontWeightMedium];
        
        self.unreadView.hidden = NO;
        self.unreadView.clipsToBounds = YES;
        
        if (unreadCount > 0) {
            self.unreadCount.text = [NSString stringWithFormat:@"%td", unreadCount];
        } else {
            self.unreadCount.text = [NSString stringWithFormat:@"%td+", -unreadCount];
        }
    } else {
        self.chatLastMessage.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.chatLastMessage.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
        self.chatLastTime.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        self.chatLastTime.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
        
        self.unreadView.hidden = YES;
        self.unreadCount.text = nil;
    }
}

#pragma mark - Public

- (void)configureCellForArchivedChat {
    self.chatLastMessage.textColor = UIColor.mnz_secondaryLabel;
    
    self.unreadView.hidden = NO;
    self.unreadView.backgroundColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    self.unreadCount.font = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium];
    self.unreadCount.text = NSLocalizedString(@"archived", @"Title of flag of archived chats.").localizedUppercaseString;
    self.unreadCountLabelHorizontalMarginConstraint.constant = 7;
    self.activeCallImageView.hidden = YES;
}

- (void)configureCellForChatListItem:(MEGAChatListItem *)chatListItem isMuted:(BOOL)muted {
    self.chatListItem = chatListItem;
    [self.timer invalidate];

    self.privateChatImageView.hidden = chatListItem.isPublicChat;

    self.chatTitle.text = self.chatListItem.chatTitle;
    [self updateLastMessageForChatListItem:chatListItem];
    
    [self configureAvatar:chatListItem];
    if (chatListItem.isGroup) {
        self.onlineStatusView.hidden = YES;
    } else {
        UIColor *statusColor = [UIColor mnz_colorForChatStatus:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:chatListItem.peerHandle]];
        if (statusColor) {
            self.onlineStatusView.backgroundColor = statusColor;
            self.onlineStatusView.hidden = NO;
        } else {
            self.onlineStatusView.hidden = YES;
        }
    }
    
    self.onCallDuration.hidden = YES;
    self.activeCallImageView.hidden = YES;
    if ([[MEGASdkManager sharedMEGAChatSdk] hasCallInChatRoom:chatListItem.chatId] && MEGAReachabilityManager.isReachable) {
        MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:chatListItem.chatId];
        BOOL is1on1AndThereAreNoNewMessages = !chatListItem.isGroup && self.unreadView.hidden;
        if (is1on1AndThereAreNoNewMessages || chatListItem.isGroup) {
            switch (call.status) {
                case MEGAChatCallStatusInProgress:
                    self.onCallDuration.hidden = NO;
                    self.chatLastMessage.text = NSLocalizedString(@"Ongoing Call", @"Text to inform the user there is an active call and is not participating");
                    self.chatLastMessage.text = [self.chatLastMessage.text stringByAppendingString:@" •"];
                    self.activeCallImageView.hidden = NO;
                    break;
                    
                case MEGAChatCallStatusUserNoPresent:
                    self.activeCallImageView.hidden = NO;
                    if (call.isRinging) {
                        self.chatLastMessage.text = NSLocalizedString(@"Incoming call", @"notification subtitle of incoming calls");
                    } else {
                        self.chatLastMessage.text = NSLocalizedString(@"Ongoing Call", @"Text to inform the user there is an active call and is not participating");
                    }
                    break;
                    
                case MEGAChatCallStatusInitial:
                case MEGAChatCallStatusConnecting:
                case MEGAChatCallStatusJoining:
                    if (!call.isRinging) {
                        self.chatLastMessage.text = NSLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
                    }
                    break;

                    
                default:
                    break;
            }
            
            if (!self.timer.valid && call.status == MEGAChatCallStatusInProgress) {
                self.initDuration = call.duration;
                self.baseDate = [NSDate date];
                self.onCallDuration.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
                [self updateDuration];
                self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
            }
        }
        self.chatLastMessage.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    }
    
    [self updateUnreadCountChange:chatListItem.unreadCount];
    self.mutedChatImageView.hidden = !muted;
}

- (void)configureCellForUser:(MEGAUser *)user {
    self.privateChatImageView.hidden = YES;
    
    self.chatTitle.text = user.mnz_displayName;
    self.chatLastMessage.text = NSLocalizedString(@"noConversationHistory", @"Information if there are no history messages in current chat conversation");
    
    [self.avatarView.avatarImageView mnz_setImageForUserHandle:user.handle name:[user mnz_fullName]];
    [self.avatarView configureWithMode:MegaAvatarViewModeSingle];
    UIColor *statusColor = [UIColor mnz_colorForChatStatus:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:user.handle]];
    if (statusColor) {
        self.onlineStatusView.backgroundColor = statusColor;
        self.onlineStatusView.hidden = NO;
    } else {
        self.onlineStatusView.hidden = YES;
    }
    
    self.activeCallImageView.hidden = YES;
    self.chatLastTime.hidden = YES;
    
    [self updateUnreadCountChange:0];
}

- (void)configureAvatar:(MEGAChatListItem *)chatListItem {
    if (chatListItem.isGroup) {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatListItem.chatId];
        [self.avatarView setupFor:chatRoom];
    } else {
        [self.avatarView.avatarImageView mnz_setImageForUserHandle:chatListItem.peerHandle name:chatListItem.title];
        [self.avatarView configureWithMode:MegaAvatarViewModeSingle];
    }
}

- (void)updateDuration {
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
    self.onCallDuration.text = [NSString mnz_stringFromTimeInterval:interval];
}

- (void)updateUnreadCountChange:(NSInteger)unreadCount { //Rename?
    self.chatTitle.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] fontWithWeight:UIFontWeightMedium];
    
    [self manageUnreadMessages:unreadCount];
}

- (void)updateLastMessageForChatListItem:(MEGAChatListItem *)item {
    self.chatListItem = item;
    
    self.onCallDuration.hidden = YES;
    
    switch (item.lastMessageType) {
            
        case 255: {
            self.chatLastMessage.text = NSLocalizedString(@"loading", @"state previous to import a file");
            self.chatLastTime.hidden = YES;
            break;
        }
            
        case MEGAChatMessageTypeInvalid: {
            self.chatLastMessage.text = NSLocalizedString(@"noConversationHistory", @"Information if there are no history messages in current chat conversation");
            self.chatLastTime.hidden = YES;
            break;
        }
            
        case MEGAChatMessageTypeAttachment: {
            NSString *senderString;
            if (item.group) {
                senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:YES];
            }
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *attachedFileString = NSLocalizedString(@"attachedFile", @"A message appearing in the chat summary window when the most recent action performed by a user was attaching a file. Please keep %s as it will be replaced at runtime with the name of the attached file.");
                lastMessageString = [attachedFileString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = NSLocalizedString(@"attachedXFiles", @"A summary message when a user has attached many files at once into the chat. Please keep %s as it will be replaced at runtime with the number of files.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%tu", componentsArray.count]];
            }
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, lastMessageString] : lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypeVoiceClip : {
            NSString *senderString;
            if (item.group) {
                senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:YES];
            }
            
            MEGAChatMessage *lastMessage = [[MEGASdkManager sharedMEGAChatSdk] messageForChat:item.chatId messageId:item.lastMessageId];
            NSString *durationString;
            if (lastMessage.nodeList && lastMessage.nodeList.size.integerValue == 1) {
                MEGANode *node = [lastMessage.nodeList nodeAtIndex:0];
                NSTimeInterval duration = node.duration > 0 ? node.duration : 0;
                durationString = [NSString mnz_stringFromTimeInterval:duration];
            } else {
                durationString = @"00:00";
            }
            
            NSMutableAttributedString *lastMessageMutableAttributedString = senderString ? [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", senderString]].mutableCopy : [[NSAttributedString alloc] initWithString:@""].mutableCopy;
            NSString *voiceMessageImageName = self.chatListItem.unreadCount ? @"voiceMessage" : @"voiceMessageGrey";
            NSAttributedString *microphoneImageAttributedString = [NSAttributedString mnz_attributedStringFromImageNamed:voiceMessageImageName fontCapHeight:self.chatLastMessage.font.capHeight];
            [lastMessageMutableAttributedString appendAttributedString:microphoneImageAttributedString];
            [lastMessageMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:durationString]];
            
            self.chatLastMessage.attributedText = lastMessageMutableAttributedString;
            
            break;
        }
            
        case MEGAChatMessageTypeContact: {
            NSString *senderString;
            if (item.group) {
                senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:YES];
            }
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *sentContactString = NSLocalizedString(@"sentContact", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [sentContactString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = NSLocalizedString(@"sentXContacts", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%tu", componentsArray.count]];
            }
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, lastMessageString] : lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypeTruncate: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            NSString *lastMessageString = NSLocalizedString(@"clearedTheChatHistory", @"A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.");
            lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"[A]" withString:senderString];
            self.chatLastMessage.text = lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypePrivilegeChange: {
            NSString *fullNameDidAction = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
            
            NSString *fullNameReceiveAction = [chatRoom userDisplayNameForUserHandle:item.lastMessageHandle];
            if (!fullNameReceiveAction) {
                fullNameReceiveAction = @"Unknown";
                MEGALogWarning(@"[Chat Links Scalability] Display name not ready");
            }
            
            NSString *wasChangedToBy = NSLocalizedString(@"wasChangedToBy", @"A log message in a chat to display that a participant's permission was changed and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the permission name (such as Moderator or Read-only) and [C] will be replaced with the person who did it. Please keep the [A], [B] and [C] placeholders, they will be replaced at runtime. For example: Alice Jones was changed to Moderator by John Smith.");
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
            NSString *privilige;
            switch (item.lastMessagePriv) {
                case 0:
                    privilige = NSLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
                    break;
                    
                case 2:
                    privilige = NSLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.");
                    break;
                    
                case 3:
                    privilige = NSLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat");
                    break;
                    
                default:
                    privilige = @"";
                    break;
            }
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[B]" withString:privilige];
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[C]" withString:fullNameDidAction];
            self.chatLastMessage.text = wasChangedToBy;
            break;
        }
            
        case MEGAChatMessageTypeAlterParticipants: {
            NSString *fullNameDidAction = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
            
            NSString *fullNameReceiveAction = [chatRoom userDisplayNameForUserHandle:item.lastMessageHandle];
            if (!fullNameReceiveAction) {
                fullNameReceiveAction = @"Unknown";
                MEGALogWarning(@"[Chat Links Scalability] Display name not ready");
            }
            
            switch (item.lastMessagePriv) {
                case -1: {
                    if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                        NSString *wasRemovedFromTheGroupChatBy = NSLocalizedString(@"wasRemovedFromTheGroupChatBy", @"A log message in a chat conversation to tell the reader that a participant [A] was removed from the group chat by the moderator [B]. Please keep [A] and [B], they will be replaced by the participant and the moderator names at runtime. For example: Alice was removed from the group chat by Frank.");
                        wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                        self.chatLastMessage.text = wasRemovedFromTheGroupChatBy;
                    } else {
                        NSString *leftTheGroupChat = NSLocalizedString(@"leftTheGroupChat", @"A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.");
                        leftTheGroupChat = [leftTheGroupChat stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        self.chatLastMessage.text = leftTheGroupChat;
                    }
                    break;
                }
                    
                case -2: {
                    if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                        NSString *joinedTheGroupChatByInvitationFrom = NSLocalizedString(@"joinedTheGroupChatByInvitationFrom", @"A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.");
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                        self.chatLastMessage.text = joinedTheGroupChatByInvitationFrom;
                    } else {
                        NSString *joinedTheGroupChat = [NSString stringWithFormat:NSLocalizedString(@"%@ joined the group chat.", @"Management message shown in a chat when the user %@ joined it from a public chat link"), fullNameReceiveAction];
                        self.chatLastMessage.text = joinedTheGroupChat;
                    }
                    break;
                }
                    
                default:
                    break;
            }
            break;
        }
        
        case MEGAChatMessageTypeSetRetentionTime: {
            NSString *text;
            NSString *fullNameDidAction = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:item.chatId];
            if (chatRoom.retentionTime <= 0) {
                text = NSLocalizedString(@"[A]%1$s[/A][B] disabled message clearing.[/B]", @"System message that is shown to all chat participants upon disabling the Retention history.");
                text = text.mnz_removeWebclientFormatters;
                
                text = [text stringByReplacingOccurrencesOfString:@"%1$s" withString:fullNameDidAction];
            } else {
                text = NSLocalizedString(@"[A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]", @"System message displayed to all chat participants when one of them enables retention history");
                text = text.mnz_removeWebclientFormatters;
                
                text = [text stringByReplacingOccurrencesOfString:@"%1$s" withString:fullNameDidAction];
                
                NSString *retentionTimeString = [NSString mnz_hoursDaysWeeksMonthsOrYearFrom:chatRoom.retentionTime];
                NSString *lastMessage = [NSAttributedString mnz_attributedStringFromMessage:retentionTimeString font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] color:UIColor.mnz_label].string;
                text = [text stringByReplacingOccurrencesOfString:@"%2$s" withString:lastMessage];
            }
            
            self.chatLastMessage.text = text;
            break;
        }
        
        case MEGAChatMessageTypeChatTitle: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            NSString *changedGroupChatNameTo = NSLocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
            changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:senderString];
            changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:(item.lastMessage ? item.lastMessage : @" ")];
            self.chatLastMessage.text = changedGroupChatNameTo;
            break;
        }
            
        case MEGAChatMessageTypeCallEnded: {
            char SOH = 0x01;
            NSString *separator = [NSString stringWithFormat:@"%c", SOH];
            NSArray *array = [item.lastMessage componentsSeparatedByString:separator];
            NSNumber *duration = item.group ? nil : @([array.firstObject integerValue]);
            MEGAChatMessageEndCallReason endCallReason = [[array objectAtIndex:1] integerValue];
            NSString *lastMessage = [NSString mnz_stringByEndCallReason:endCallReason userHandle:item.lastMessageSender duration:duration isGroup:item.isGroup];
            self.chatLastMessage.text = lastMessage;
            break;
        }
            
        case MEGAChatMessageTypeCallStarted: {
            self.chatLastMessage.text = NSLocalizedString(@"Ongoing Call", @"Text to inform the user there is an active call and is not participating");
            break;
        }

        case MEGAChatMessageTypePublicHandleCreate: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            NSString *publicHandleCreated = [NSString stringWithFormat:NSLocalizedString(@"%@ created a public link for the chat.", @"Management message shown in a chat when the user %@ creates a public link for the chat"), senderString];
            self.chatLastMessage.text = publicHandleCreated;
            break;
        }
            
        case MEGAChatMessageTypePublicHandleDelete: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            NSString *publicHandleRemoved = [NSString stringWithFormat:NSLocalizedString(@"%@ removed a public link for the chat.", @"Management message shown in a chat when the user %@ removes a public link for the chat"), senderString];
            self.chatLastMessage.text = publicHandleRemoved;
            break;
        }
            
        case MEGAChatMessageTypeSetPrivateMode: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:NO];
            NSString *setPrivateMode = [NSString stringWithFormat:NSLocalizedString(@"%@ enabled Encrypted Key Rotation", @"Management message shown in a chat when the user %@ enables the 'Encrypted Key Rotation'"), senderString];
            self.chatLastMessage.text = setPrivateMode;
            break;
        }

        default: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item pronoumForMe:YES];
            
            if (item.lastMessageType == MEGAChatMessageTypeContainsMeta) {
                MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
                MEGAChatMessage *message = [[MEGASdkManager sharedMEGAChatSdk] messageForChat:chatRoom.chatId messageId:item.lastMessageId];
                
                if (message.containsMeta.type == MEGAChatContainsMetaTypeGeolocation) {
                    NSMutableAttributedString *lastMessageMutableAttributedString = senderString ? [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", senderString]].mutableCopy : [[NSAttributedString alloc] initWithString:@""].mutableCopy;
                    NSString *locationMessageImageName = self.chatListItem.unreadCount ? @"locationMessage" : @"locationMessageGrey";
                    NSAttributedString *pinImageAttributedString = [NSAttributedString mnz_attributedStringFromImageNamed:locationMessageImageName fontCapHeight:self.chatLastMessage.font.capHeight];
                    [lastMessageMutableAttributedString appendAttributedString:pinImageAttributedString];
                    [lastMessageMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pinned Location", @"Text shown in location-type messages")]];

                    self.chatLastMessage.attributedText = lastMessageMutableAttributedString;
                    
                    break;
                }
            }
            
            NSString *lastMessage = [NSAttributedString mnz_attributedStringFromMessage:item.lastMessage font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] color:UIColor.mnz_label].string;
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, lastMessage] : lastMessage;
            break;
        }
    }
    self.chatLastTime.hidden = NO;
    self.chatLastTime.text = item.lastMessageDate.mnz_stringForLastMessageTs;
}

- (NSString *)actionAuthorNameInChatListItem:(MEGAChatListItem *)item pronoumForMe:(BOOL)me {
    NSString *actionAuthor;
    if (item.lastMessageSender == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        actionAuthor = me ? NSLocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.") : MEGASdkManager.sharedMEGAChatSdk.myFullname;
    } else {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:item.chatId];
        actionAuthor = [chatRoom userDisplayNameForUserHandle:item.lastMessageSender];
        if (!actionAuthor) {
            MEGALogWarning(@"[Chat Links Scalability] Display name not ready");
        }
    }

    return actionAuthor ?: @"Unknown";
}

@end
