#import "MyAccountHallViewController.h"

#import "AchievementsViewController.h"
#import "ContactLinkQRViewController.h"
#import "ContactsViewController.h"
#import "Helper.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MyAccountHallTableViewCell.h"
#import "NotificationsTableViewController.h"
#import "OfflineViewController.h"
#import "SettingsTableViewController.h"
#import "TransfersWidgetViewController.h"
#import "UIImage+MNZCategory.h"
#import "UsageViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface MyAccountHallViewController () <UITableViewDelegate, MEGAPurchasePricingDelegate, MEGAGlobalDelegate, MEGARequestDelegate, AudioPlayerPresenterProtocol>

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewAndEditProfileButton;
@property (weak, nonatomic) IBOutlet UIImageView *viewAndEditProfileImageView;
@property (weak, nonatomic) IBOutlet UIView *profileBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *addPhoneNumberView;
@property (weak, nonatomic) IBOutlet UIImageView *addPhoneNumberImageView;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberTitle;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberDescription;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *addPhoneNumberActivityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

@property (weak, nonatomic) IBOutlet UIView *tableFooterContainerView;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewAndEditProfileLabel.text = LocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    self.viewAndEditProfileButton.accessibilityLabel = LocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    
    [self registerCustomCells];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAndEditProfileTouchUpInside:)];
    self.profileView.gestureRecognizers = @[tapGestureRecognizer];
    
    self.avatarImageView.image = self.avatarImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.qrCodeImageView.image = self.qrCodeImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.viewAndEditProfileImageView.image = self.viewAndEditProfileImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.addPhoneNumberImageView.image = self.addPhoneNumberImageView.image.imageFlippedForRightToLeftLayoutDirection;
    
    [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray addObject:self];
    
    UITapGestureRecognizer *tapAvatarGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(avatarTapped:)];
    self.avatarImageView.gestureRecognizers = @[tapAvatarGestureRecognizer];
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    self.addPhoneNumberView.hidden = YES;
    
    [self configAddPhoneNumberTexts];
    
    [self updateAppearance];
    
    [self setUpInvokeCommands];
    
    self.isBackupSectionVisible = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self addSubscriptions];
    
    [self loadContent];
    
    [self configAddPhoneNumberView];
    
    [self checkIfBackupRootNodeExistsAndIsNotEmpty];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeSubscriptions];
    
    if (self.isMovingFromParentViewController) {
        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray removeObject:self];
    }
    
    NSInteger index = self.navigationController.viewControllers.count-1;
    if (![self.navigationController.viewControllers[index] isKindOfClass:OfflineViewController.class] &&
        !self.isMovingFromParentViewController) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [TransfersWidgetViewController.sharedTransferViewController.progressView hideWidget];
    [AudioPlayerManager.shared addDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSInteger index = self.navigationController.viewControllers.count-1;
    if ([self.navigationController.viewControllers[index] isKindOfClass:OfflineViewController.class] ||
        self.isMovingFromParentViewController) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.profileView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    self.viewAndEditProfileLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.qrCodeImageView.image = [UIImage imageNamed:@"qrCodeIcon"].imageFlippedForRightToLeftLayoutDirection;
    self.profileBottomSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.addPhoneNumberView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    
    if ([MEGASdkManager.sharedMEGASdk isAccountType:MEGAAccountTypeBusiness] ||
        [MEGASdkManager.sharedMEGASdk isAccountType:MEGAAccountTypeProFlexi]) {
        self.accountTypeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
        
        self.tableFooterContainerView.backgroundColor = [UIColor mnz_tertiaryBackgroundGrouped:self.traitCollection];
        self.tableFooterLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    }
    
    [self setMenuCapableBackButtonWithMenuTitle:LocalizedString(@"My Account", @"")];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                     NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}
                                                          forState:UIControlStateNormal];
    
    [self setupNavigationBarColorWith:self.traitCollection];
}

- (void)configAddPhoneNumberTexts {
    self.addPhoneNumberTitle.text = LocalizedString(@"Add Your Phone Number", @"");
    
    if (!MEGASdkManager.sharedMEGASdk.isAchievementsEnabled) {
        self.addPhoneNumberDescription.text = LocalizedString(@"Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.", @"");
    } else {
        [self.addPhoneNumberActivityIndicator startAnimating];
        [MEGASdkManager.sharedMEGASdk getAccountAchievementsWithDelegate:[[MEGAGenericRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            [self.addPhoneNumberActivityIndicator stopAnimating];
            if (error.type == MEGAErrorTypeApiOk) {
                NSString *storageText = [NSString memoryStyleStringFromByteCount:[request.megaAchievementsDetails classStorageForClassId:MEGAAchievementAddPhone]];
                self.addPhoneNumberDescription.text = [NSString stringWithFormat:LocalizedString(@"Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", @""), storageText];
            }
        }]];
    }
}

- (void)configAddPhoneNumberView {
    if (MEGASdkManager.sharedMEGASdk.smsVerifiedPhoneNumber != nil || MEGASdkManager.sharedMEGASdk.smsAllowedState != SMSStateOptInAndUnblock) {
        self.profileBottomSeparatorView.hidden = YES;
        self.addPhoneNumberView.hidden = YES;
    } else {
        self.profileBottomSeparatorView.hidden = NO;
        if (self.addPhoneNumberView.isHidden) {
            [UIView animateWithDuration:.75 animations:^{
                self.addPhoneNumberView.hidden = NO;
            }];
        }
    }
}

- (void)avatarTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
        contactLinkVC.scanCode = NO;
        contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:contactLinkVC animated:YES completion:nil];
    }
}

#pragma mark - IBActions

- (IBAction)scanQrCode:(UIBarButtonItem *)sender {
    ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
    contactLinkVC.scanCode = YES;
    contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:contactLinkVC animated:YES completion:nil];
}

- (IBAction)buyPROTouchUpInside:(UIBarButtonItem *)sender {
    [self showUpgradePlanView];
}

- (IBAction)viewAndEditProfileTouchUpInside:(UIButton *)sender {
    [self showProfileView];
}

- (IBAction)didTapAddPhoneNumberView {
    [[[SMSVerificationViewRouter alloc] initWithVerificationType:SMSVerificationTypeAddPhoneNumber presenter:self onPhoneNumberVerified: nil] start];
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    BOOL isEnabled = ![self isNewUpgradeAccountPlanEnabled];
    self.buyPROBarButtonItem.enabled = isEnabled;
}

#pragma mark - AudioPlayer

- (void)updateContentView:(CGFloat)height {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

@end
