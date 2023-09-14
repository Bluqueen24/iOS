#import "FileLinkViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGALinkManager.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "SendToViewController.h"
#import "UnavailableLinkView.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface FileLinkViewController ()

@property (strong, nonatomic) UILabel *navigationBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendToBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, getter=isFolderEmpty) BOOL folderEmpty;

@property (nonatomic) BOOL decryptionAlertControllerHasBeenPresented;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.cancelBarButtonItem.title = LocalizedString(@"close", @"A button label.");
    self.moreBarButtonItem.image = [UIImage imageNamed:@"moreNavigationBar"];
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
    
    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];

    [self.openButton setTitle:LocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
    [self.importButton setTitle:LocalizedString(@"Import to Cloud Drive", @"Button title that triggers the importing link action") forState:UIControlStateNormal];
    
    [self setUIItemsHidden:YES];
    
    [self processRequestResult];
    
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    
    self.moreBarButtonItem.accessibilityLabel = LocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    [self updateAppearance];
    [self configureContextMenuManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNavigationBarTitleLabel];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setNavigationBarTitleLabel];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        MEGALinkManager.secondaryLinkURL = nil;
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    self.mainView.backgroundColor = [UIColor mnz_secondaryBackgroundElevated:self.traitCollection];
    
    self.sizeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.importButton mnz_setupPrimary:self.traitCollection];
    [self.openButton mnz_setupBasic:self.traitCollection];
}

- (void)processRequestResult {
    [SVProgressHUD dismiss];
    
    if (self.error.type) {
        if (self.error.hasExtraInfo) {
            if (self.error.linkStatus == MEGALinkErrorCodeDownETD) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorETDDown];
            } else if (self.error.userStatus == MEGAUserErrorCodeETDSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserETDSuspension];
            } else if (self.error.userStatus == MEGAUserErrorCodeCopyrightSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserCopyrightSuspension];
            } else {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
            }
        } else {
            switch (self.error.type) {
                case MEGAErrorTypeApiEArgs: {
                    if (self.decryptionAlertControllerHasBeenPresented) {
                        [self showDecryptionKeyNotValidAlert];
                    } else {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
                    
                case MEGAErrorTypeApiEBlocked:
                case MEGAErrorTypeApiENoent:
                case MEGAErrorTypeApiETooMany: {
                    [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    break;
                }
                    
                case MEGAErrorTypeApiEIncomplete: {
                    [self showDecryptionAlert];
                    break;
                }
                    
                default:
                    break;
            }
        }
        
        return;
    }
    
    if (self.request.flag) {
        if (self.decryptionAlertControllerHasBeenPresented) { //Link without key, after entering a bad one
            [self showDecryptionKeyNotValidAlert];
        } else { //Link with invalid key
            [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
        }
        return;
    }
    
    self.node = self.request.publicNode;
    
    if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:self.node.name]) {
        [self dismissViewControllerAnimated:YES completion:^{
            MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[self.node].mutableCopy api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeFileLink presentingNode:self.node];
            photoBrowserVC.publicLink = self.publicLinkString;
            
            [UIApplication.mnz_presentingViewController presentViewController:photoBrowserVC animated:YES completion:nil];
        }];
    } else {
        [self setNodeInfo];
        if (self.node.size.longLongValue < MEGAMaxFileLinkAutoOpenSize && ![FileExtensionGroupOCWrapper verifyIsMultiMedia:self.node.name]) {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
                [UIApplication.mnz_presentingViewController presentViewController:[self.node mnz_viewControllerForNodeInFolderLink:YES fileLink:link] animated:YES completion:nil];
            }];
        }
    }
}

- (void)setNavigationBarTitleLabel {
    if (self.node.name != nil) {
        UILabel *label = [UILabel.new customNavigationBarLabelWithTitle:self.node.name subtitle:LocalizedString(@"fileLink", @"") color:UIColor.mnz_label];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        self.navigationBarLabel = label;
        self.navigationItem.titleView = self.navigationBarLabel;
    } else {
        self.navigationItem.title = LocalizedString(@"fileLink", @"");
    }
}

- (void)setUIItemsHidden:(BOOL)boolValue {
    self.mainView.hidden = boolValue;
    self.openButton.hidden = boolValue;
}

- (void)showUnavailableLinkViewWithError:(UnavailableLinkError)error {
    self.moreBarButtonItem.enabled = self.shareLinkBarButtonItem.enabled = self.sendToBarButtonItem.enabled = NO;
    self.navigationBarLabel = [UILabel.new customNavigationBarLabelWithTitle:LocalizedString(@"fileLink", @"") subtitle:LocalizedString(@"Unavailable", @"Text used to show the user that some resource is not available") color:UIColor.mnz_label];
    self.navigationItem.titleView = self.navigationBarLabel;
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    switch (error) {
        case UnavailableLinkErrorGeneric:
            [unavailableLinkView configureInvalidFileLink];
            break;
            
        case UnavailableLinkErrorETDDown:
            [unavailableLinkView configureInvalidFileLinkByETD];
            break;
            
        case UnavailableLinkErrorUserETDSuspension:
            [unavailableLinkView configureInvalidFileLinkByUserETDSuspension];
            break;
            
        case UnavailableLinkErrorUserCopyrightSuspension:
            [unavailableLinkView configureInvalidFolderLinkByUserCopyrightSuspension];
            break;
    }
    unavailableLinkView.frame = self.view.bounds;
    [self.view addSubview:unavailableLinkView];
}

- (void)showDecryptionAlert {
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"decryptionKeyAlertTitle", @"Alert title shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") message:LocalizedString(@"decryptionKeyAlertMessage", @"Alert message shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = LocalizedString(@"decryptionKey", @"Hint text to suggest that the user has to write the decryption key");
        [textField addTarget:self action:@selector(decryptionAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *decryptAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"decrypt", @"Button title to try to decrypt the link") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            NSString *linkString = [MEGALinkManager buildPublicLink:self.publicLinkString withKey:decryptionAlertController.textFields.firstObject.text isFolder:NO];
            
            MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
                self.request = request;
                self.error = error;
                [self processRequestResult];
            }];
            delegate.savePublicHandle = YES;
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:linkString delegate:delegate];
        }
    }];
    decryptAlertAction.enabled = NO;
    [decryptionAlertController addAction:decryptAlertAction];
    
    [self presentViewController:decryptionAlertController animated:YES completion:^{
        self.decryptionAlertControllerHasBeenPresented = YES;
    }];
}

- (void)showDecryptionKeyNotValidAlert {
    UIAlertController *decryptionKeyNotValidAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"decryptionKeyNotValid", @"Alert title shown when you have written a decryption key not valid") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionKeyNotValidAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"nil") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showDecryptionAlert];
    }]];
    
    [self presentViewController:decryptionKeyNotValidAlertController animated:YES completion:nil];
}

- (void)setNodeInfo {
    NSString *name = self.node.name;
    self.nameLabel.text = name;
    [self setNavigationBarTitleLabel];
    
    self.sizeLabel.text = [NSString memoryStyleStringFromByteCount:self.node.size.longLongValue];
    
    [self.thumbnailImageView mnz_setThumbnailByNode:self.node];
    
    [self setUIItemsHidden:NO];
}

- (void)decryptionAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *decryptionAlertController = (UIAlertController *)self.presentedViewController;
    if ([decryptionAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = decryptionAlertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

- (void)importFromFiles {
    [self.node mnz_fileLinkImportFromViewController:self isFolderLink:NO];
}

- (void)open {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
        [self.node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:link messageId:nil chatId:nil allNodes: nil];
    }
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [MEGALinkManager resetUtilsForLinksWithoutSession];

    [SVProgressHUD dismiss];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)importAction:(UIButton *)sender {
    [self importFromFiles];
}

- (IBAction)openAction:(UIButton *)sender {
    [self open];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    [self showShareLink];
}

- (IBAction)sendToContactAction:(UIBarButtonItem *)sender {
    [self showSendToChat];
}

@end
