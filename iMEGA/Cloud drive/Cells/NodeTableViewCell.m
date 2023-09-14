#import "NodeTableViewCell.h"

#import "MEGANodeList+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@import MEGASDKRepo;
@import MEGAL10nObjc;

@interface NodeTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *infoStringRightLabel;

@end

@implementation NodeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.cancelButtonTrailingConstraint.constant =  ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhonePlus]) ? 10 : 6;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = self.subviews.count == 3; // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        self.moreButton.hidden = YES;
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 102, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
            [self layoutIfNeeded];
        }];
        
        if (!self.recentActionBucket) {
            self.moreButton.hidden = self.isNodeInRubbishBin || self.isNodeInBrowserView;
        }
    }
}

- (void)configureCellForNode:(MEGANode *)node api:(MEGASdk *)api {
    self.node = node;
    
    self.downloadingArrowImageView.hidden = self.downloadProgressView.hidden = YES;
    
    self.moreButton.hidden = self.isNodeInRubbishBin;
    
    if (self.downloadingArrowView != nil) {
        self.downloadingArrowView.hidden = self.downloadingArrowImageView.isHidden;
    }
    
    self.favouriteView.hidden = !node.isFavourite;
    self.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        self.labelImageView.image = [UIImage imageNamed:labelString];
    }
    BOOL isDownloaded = (node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    self.downloadedImageView.hidden = !isDownloaded;
    if (self.downloadedView != nil) {
        self.downloadedView.hidden = self.downloadedImageView.isHidden;
    }
    self.linkView.hidden = !node.isExported || node.mnz_isInRubbishBin;
    
    if (node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
            self.thumbnailPlayImageView.hidden = ![FileExtensionGroupOCWrapper verifyIsVideo:node.name];
            self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
        } else {
            MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (request.nodeHandle == self.node.handle) {
                    self.thumbnailPlayImageView.hidden = ![FileExtensionGroupOCWrapper verifyIsVideo:node.name];
                    self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:request.file];
                }
            }];
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
            [self.thumbnailImageView setImage:[NodeAssetsManager.shared iconFor:node]];
        }
    } else {
        [self.thumbnailImageView setImage:[NodeAssetsManager.shared iconFor:node]];
    }
    
    if (![FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        self.thumbnailPlayImageView.hidden = YES;
    }
        
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node attributedTakenDownName];
        self.nameLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    } else {
        self.nameLabel.text = node.name;
        self.nameLabel.textColor = UIColor.mnz_label;
        self.subtitleLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    }
    
    self.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    if (node.isFile) {
        MEGASdk *megaSDK = self.recentActionBucket ? MEGASdkManager.sharedMEGASdk : api;
        switch (self.cellFlavor) {
            case NodeTableViewCellFlavorVersions:
            case NodeTableViewCellFlavorRecentAction:
            case NodeTableViewCellFlavorCloudDrive: {
                self.infoLabel.text =
                    self.recentActionBucket ? [Helper sizeAndCreationHourAndMininuteForNode:node api:megaSDK] :
                    [Helper sizeAndModicationDateForNode:node api:megaSDK];
                [MEGASdkManager.sharedMEGASdk hasVersionsForNode:node completion:^(BOOL hasVersions) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.versionedImageView.hidden = !hasVersions;
                    });
                }];
                break;
            }
            case NodeTableViewCellFlavorSharedLink: {
                self.infoLabel.text = [Helper sizeAndShareLinkCreateDateForSharedLinkNode:node api:megaSDK];
                [MEGASdkManager.sharedMEGASdk hasVersionsForNode:node completion:^(BOOL hasVersions) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.versionedImageView.hidden = !hasVersions;
                    });
                }];
                break;
            }
            case NodeTableViewCellExplorerView:
                [self updateInfo];
                break;
        }
    } else if (node.isFolder) {
        self.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:api];
        self.versionedImageView.hidden = YES;
    }
    
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    self.separatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket {
    self.cellFlavor = NodeTableViewCellFlavorRecentAction;
    [self updateWithTrait:[self traitCollection]];
    self.leadingConstraint.constant = 24;
    self.recentActionBucket = recentActionBucket;
    
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    [self setTitleAndFolderNameFor:recentActionBucket withNodes:nodesArray];
    
    BOOL isMultipleNodes = nodesArray.count > 1;
    self.moreButton.hidden = isMultipleNodes;
    self.disclosureIndicatorView.hidden = !isMultipleNodes;
    
    MEGANode *node = nodesArray.firstObject;
    [self.thumbnailImageView setImage:[NodeAssetsManager.shared iconFor:node]];
    self.thumbnailPlayImageView.hidden = node.hasThumbnail ? ![FileExtensionGroupOCWrapper verifyIsVideo:node.name] : YES;
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    MEGAShareType shareType = [MEGASdkManager.sharedMEGASdk accessLevelForNode:node];
    if ([recentActionBucket.userEmail isEqualToString:MEGASdk.currentUserEmail]) {
        if (shareType == MEGAShareTypeAccessOwner) {
            MEGANode *firstbornParentNode = [[MEGASdkManager.sharedMEGASdk nodeForHandle:recentActionBucket.parentHandle] mnz_firstbornInShareOrOutShareParentNode];
            if (firstbornParentNode.isOutShare) {
                self.incomingOrOutgoingView.hidden = NO;
                self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_outgoing"];
            } else {
                self.incomingOrOutgoingView.hidden = YES;
            }
        } else {
            self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
            self.incomingOrOutgoingImageView.hidden = NO;
            self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_incoming"];
        }
    } else {
        self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
        self.incomingOrOutgoingImageView.hidden = NO;
        self.incomingOrOutgoingImageView.image = (shareType == MEGAShareTypeAccessOwner) ? [UIImage imageNamed:@"mini_folder_outgoing"] : [UIImage imageNamed:@"mini_folder_incoming"];
    }

    self.uploadOrVersionImageView.image = recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    
    self.timeLabel.text = recentActionBucket.timestamp.mnz_formattedHourAndMinutes;
    
    self.subtitleLabel.textColor = self.infoLabel.textColor = self.timeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)moreButtonPressed:(UIButton *)moreButton {
    self.moreButtonAction(moreButton);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateWithTrait:self.traitCollection];
    }
}

- (void)updateWithTrait:(UITraitCollection *)currentTraitCollection {
    self.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    if (self.cellFlavor != NodeTableViewCellFlavorRecentAction) {
        return;
    }
    self.backgroundColor = [UIColor mnz_homeRecentsCellBackgroundForTraitCollection:currentTraitCollection];
}

- (void)updateInfo {
    if (self.cellFlavor == NodeTableViewCellExplorerView && self.node != nil) {
        self.infoStringRightLabel.lineBreakMode = NSLineBreakByTruncatingHead;
        BOOL shouldIncludeRootFolder = self.node.isInShare
        || (self.node.parentHandle == MEGASdkManager.sharedMEGASdk.rootNode.handle);
        self.infoLabel.text = shouldIncludeRootFolder ? LocalizedString(@"", @"") : LocalizedString(@"> ", @"");
        self.infoStringRightLabel.text = [self.node filePathWithDelimeter:@" > "
                                                            sdk:MEGASdkManager.sharedMEGASdk
                                          includeRootFolderName:shouldIncludeRootFolder
                                                excludeFileName:YES];
        self.versionedImageView.image = [UIImage imageNamed:self.node.isInShare ? @"pathInShares" : @"pathCloudDrive"];
        self.versionedImageView.hidden = NO;
    }
}

@end
