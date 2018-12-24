
#import "OnboardingViewController.h"

#import "DevicePermissionsHelper.h"
#import "OnboardingView.h"
#import "UIColor+MNZCategory.h"

@interface OnboardingViewController () <UIScrollViewDelegate>

@property (nonatomic) OnboardingType type;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryButton;

@end

@implementation OnboardingViewController

#pragma mark - Initialization

+ (OnboardingViewController *)onboardingViewControllerOfType:(OnboardingType)type {
    OnboardingViewController *onboardingViewController = [[UIStoryboard storyboardWithName:@"Onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"OnboardingViewControllerID"];
    onboardingViewController.type = type;
    return onboardingViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.type) {
        case OnboardingTypeDefault:
            self.pageControl.currentPageIndicatorTintColor = UIColor.mnz_redMain;
            [self.pageControl addTarget:self action:@selector(pageControlValueChanged) forControlEvents:UIControlEventValueChanged];
            
            [self.primaryButton setTitle:AMLocalizedString(@"createAccount", @"Button title which triggers the action to create a MEGA account") forState:UIControlStateNormal];
            self.primaryButton.backgroundColor = UIColor.mnz_redMain;
            
            [self.secondaryButton setTitle:AMLocalizedString(@"login", @"Button title which triggers the action to login in your MEGA account") forState:UIControlStateNormal];
            [self.secondaryButton setTitleColor:UIColor.mnz_redMain forState:UIControlStateNormal];
            
            if (self.scrollView.subviews.firstObject.subviews.count == 4) {
                OnboardingView *onboardingViewEncryption = self.scrollView.subviews.firstObject.subviews[0];
                onboardingViewEncryption.type = OnboardingViewTypeEncryptionInfo;
                OnboardingView *onboardingViewChat = self.scrollView.subviews.firstObject.subviews[1];
                onboardingViewChat.type = OnboardingViewTypeChatInfo;
                OnboardingView *onboardingViewContacts = self.scrollView.subviews.firstObject.subviews[2];
                onboardingViewContacts.type = OnboardingViewTypeContactsInfo;
                OnboardingView *onboardingViewCameraUploads = self.scrollView.subviews.firstObject.subviews[3];
                onboardingViewCameraUploads.type = OnboardingViewTypeCameraUploadsInfo;
            }
            
            break;
            
        case OnboardingTypePermissions:
            self.scrollView.userInteractionEnabled = NO;
            
            self.pageControl.currentPageIndicatorTintColor = UIColor.mnz_green00BFA5;
            self.pageControl.userInteractionEnabled = NO;
            
            [self.primaryButton setTitle:AMLocalizedString(@"Allow Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand") forState:UIControlStateNormal];
            self.primaryButton.backgroundColor = UIColor.mnz_green00BFA5;
            
            [self.secondaryButton setTitle:AMLocalizedString(@"notNow", nil) forState:UIControlStateNormal];
            [self.secondaryButton setTitleColor:UIColor.mnz_green899B9C forState:UIControlStateNormal];
            
            if (self.scrollView.subviews.firstObject.subviews.count == 4) {
                [self.scrollView.subviews.firstObject.subviews.lastObject removeFromSuperview];
                int nextIndex = 0;
                if ([DevicePermissionsHelper shouldAskForPhotosPermissions]) {
                    OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                    onboardingView.type = OnboardingViewTypePhotosPermission;
                    nextIndex++;
                } else {
                    [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
                }
                
                if ([DevicePermissionsHelper shouldAskForAudioPermissions] || [DevicePermissionsHelper shouldAskForVideoPermissions]) {
                    OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                    onboardingView.type = OnboardingViewTypeMicrophoneAndCameraPermissions;
                    nextIndex++;
                } else {
                    [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
                }
                
                if ([DevicePermissionsHelper shouldAskForNotificationsPermissions]) {
                    OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                    onboardingView.type = OnboardingViewTypeNotificationsPermission;
                    nextIndex++;
                } else {
                    [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
                }
            }
            
            break;
    }
    
    self.scrollView.delegate = self;
    self.pageControl.numberOfPages = self.scrollView.subviews.firstObject.subviews.count;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIDevice.currentDevice.iPhoneDevice) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self scrollTo:self.pageControl.currentPage];
    } completion:nil];
}

#pragma mark - Private

- (void)scrollTo:(NSUInteger)page {
    CGFloat newX = (CGFloat)page * self.scrollView.frame.size.width;
    self.scrollView.contentOffset = CGPointMake(newX, 0.0f);
    self.pageControl.currentPage = page;
}

- (void)nextPageOrDismiss {
    NSUInteger nextPage = self.pageControl.currentPage + 1;
    if (nextPage < self.pageControl.numberOfPages) {
        [self scrollTo:nextPage];
    } else {
        [self dismissViewControllerAnimated:YES completion:self.completion];
    }
}

#pragma mark - Targets

- (void)pageControlValueChanged {
    [self scrollTo:self.pageControl.currentPage];
}

#pragma mark - IBActions

- (IBAction)primaryButtonTapped:(UIButton *)sender {
    switch (self.type) {
        case OnboardingTypeDefault: {
            UINavigationController *createAccountNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CreateAccountNavigationControllerID"];
            [self presentViewController:createAccountNC animated:YES completion:nil];
            break;
        }
            
        case OnboardingTypePermissions: {
            if (self.scrollView.subviews.firstObject.subviews.count <= self.pageControl.currentPage) {
                return;
            }
            
            OnboardingView *currentView = self.scrollView.subviews.firstObject.subviews[self.pageControl.currentPage];
            switch (currentView.type) {
                case OnboardingViewTypePhotosPermission: {
                    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeMicrophoneAndCameraPermissions: {
                    [DevicePermissionsHelper audioPermissionModal:NO forIncomingCall:NO withCompletionHandler:^(BOOL granted) {
                        [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                            [self nextPageOrDismiss];
                        }];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeNotificationsPermission: {
                    [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                default:
                    [self nextPageOrDismiss];
                    break;
            }
            break;
        }
    }
}

- (IBAction)secondaryButtonTapped:(UIButton *)sender {
    switch (self.type) {
        case OnboardingTypeDefault: {
            UINavigationController *loginNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginNavigationControllerID"];
            [self presentViewController:loginNC animated:YES completion:nil];
            break;
        }
            
        case OnboardingTypePermissions:
            [self nextPageOrDismiss];
            break;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger newPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.currentPage = newPage;
}

@end
