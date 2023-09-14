#import <UIKit/UIKit.h>

#import "OnboardingType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingViewController : UIViewController

+ (OnboardingViewController *)instanciateOnboardingWithType:(OnboardingType)type;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *tertiaryButton;

@property (nonatomic, copy) void (^completion)(void);

- (void)presentLoginViewController;
- (void)presentCreateAccountViewController;

@end

NS_ASSUME_NONNULL_END
