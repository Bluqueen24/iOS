#import "MEGAAVViewController.h"

#import "LTHPasscodeViewController.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

static const NSUInteger MIN_SECOND = 10; // Save only where the users were playing the file, if the streaming second is greater than this value.

@interface MEGAAVViewController () <AVPlayerViewControllerDelegate>

@property (nonatomic, strong, nonnull) NSURL *fileUrl;
@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, assign, getter=isFolderLink) BOOL folderLink;
@property (nonatomic, assign, getter=isEndPlaying) BOOL endPlaying;
@property (nonatomic, strong) MEGASdk *apiForStreaming;
@property (nonatomic, assign, getter=isViewDidAppearFirstTime) BOOL viewDidAppearFirstTime;
@property (nonatomic, strong) NSMutableSet *subscriptions;

@end

@implementation MEGAAVViewController

- (instancetype)initWithURL:(NSURL *)fileUrl {
    self = [super init];
    
    if (self) {
        _fileUrl    = fileUrl;
        _node       = nil;
        _folderLink = NO;
        _subscriptions = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk *)apiForStreaming {
    self = [super init];
    
    if (self) {
        _apiForStreaming = apiForStreaming;
        _node            = folderLink ? [[MEGASdkManager sharedMEGASdkFolder] authorizeNode:node] : node;
        _folderLink      = folderLink;
        _fileUrl         = [apiForStreaming httpServerIsLocalOnly] ? [apiForStreaming httpServerGetLocalLink:_node] : [[apiForStreaming httpServerGetLocalLink:_node] mnz_updatedURLWithCurrentAddress];
    }
        
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [AudioSessionUseCaseOCWrapper.alloc.init configureVideoAudioSession];
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidStart];
    }

    self.viewDidAppearFirstTime = YES;
    
    self.subscriptions = [self bindToSubscriptionsWithMovieFinished:^{
        [self movieFinishedCallback];
    } checkNetworkChanges:^{
        [self checkNetworkChanges];
    } applicationDidEnterBackground:^{
        [self applicationDidEnterBackground];
    } movieStalled:^{
        [self movieStalledCallback];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *fingerprint = [self fileFingerprint];

    if (self.isViewDidAppearFirstTime) {
        if (fingerprint && ![fingerprint isEqualToString:@""]) {
            MOMediaDestination *mediaDestination = [[MEGAStore shareInstance] fetchMediaDestinationWithFingerprint:fingerprint];
            if (mediaDestination.destination.longLongValue > 0 && mediaDestination.timescale.intValue > 0) {
                if ([FileExtensionGroupOCWrapper verifyIsVideo:[self fileName]]) {
                    NSString *infoVideoDestination = LocalizedString(@"video.alert.resumeVideo.message", @"Message to show the user info (video name and time) about the resume of the video");
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%1$s" withString:[self fileName]];
                    infoVideoDestination = [infoVideoDestination stringByReplacingOccurrencesOfString:@"%2$s" withString:[self timeForMediaDestination:mediaDestination]];
                    UIAlertController *resumeOrRestartAlert = [UIAlertController alertControllerWithTitle:LocalizedString(@"video.alert.resumeVideo.title", @"Alert title shown for video with options to resume playing the video or start from the beginning") message:infoVideoDestination preferredStyle:UIAlertControllerStyleAlert];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.resume", @"Alert button title that will resume playing the video") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:mediaDestination play:YES];
                    }]];
                    [resumeOrRestartAlert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"video.alert.resumeVideo.button.restart", @"Alert button title that will start playing the video from the beginning") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self seekToDestination:nil play:YES];
                    }]];
                    [self presentViewController:resumeOrRestartAlert animated:YES completion:nil];
                } else {
                    [self seekToDestination:mediaDestination play:NO];
                }
            } else {
                [self seekToDestination:nil play:YES];
            }
        } else {
            [self seekToDestination:nil play:YES];
        }
    }
    
    [[AVPlayerManager shared] assignDelegateTo:self];
    
    self.viewDidAppearFirstTime = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self stopStreaming];

        if (![AudioPlayerManager.shared isPlayerAlive]) {
            [AudioSessionUseCaseOCWrapper.alloc.init configureDefaultAudioSession];
        }

        if ([AudioPlayerManager.shared isPlayerAlive]) {
            [AudioPlayerManager.shared audioInterruptionDidEndNeedToResume:YES];
        }
    });
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_presentingViewController.view
                                                     withAnimation:YES
                                                        withLogout:YES
                                                    andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
    }
    
    [self deallocPlayer];
    [self cancelPlayerProcess];
    self.player = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[AVPlayerManager shared] isPIPModeActiveFor:self]) {
        return;
    }

    CMTime mediaTime = CMTimeMake(self.player.currentTime.value, self.player.currentTime.timescale);
    Float64 second = CMTimeGetSeconds(mediaTime);
    
    NSString *fingerprint = [self fileFingerprint];
    
    if (fingerprint && ![fingerprint isEqualToString:@""]) {
        if (self.isEndPlaying || second <= MIN_SECOND) {
            [[MEGAStore shareInstance] deleteMediaDestinationWithFingerprint:fingerprint];
        } else {
            [[MEGAStore shareInstance] insertOrUpdateMediaDestinationWithFingerprint:fingerprint destination:[NSNumber numberWithLongLong:self.player.currentTime.value] timescale:[NSNumber numberWithInt:self.player.currentTime.timescale]];
        }
    }
}

#pragma mark - Private

- (void)seekToDestination:(MOMediaDestination *)mediaDestination play:(BOOL)play {
    if (!self.fileUrl) {
        return;
    }
    
    [self.avViewControllerDelegate willStartPlayer];

    AVAsset *asset = [AVAsset assetWithURL:self.fileUrl];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    [self.subscriptions addObject:[self bindPlayerItemStatusWithPlayerItem:playerItem]];
    
    [self seekToMediaDestination:mediaDestination];
    
    if (play) {
        [self.player play];
    }
    
    [self.subscriptions addObject:[self bindPlayerTimeControlStatus]];
}

- (void)replayVideo {
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
        self.endPlaying = NO;
    }
}

- (void)stopStreaming {
    if (self.node) {
        [self.apiForStreaming httpServerStop];
    }
}

- (NSString *)timeForMediaDestination:(MOMediaDestination *)mediaDestination {
    CMTime mediaTime = CMTimeMake(mediaDestination.destination.longLongValue, mediaDestination.timescale.intValue);
    NSTimeInterval durationSeconds = (NSTimeInterval)CMTimeGetSeconds(mediaTime);
    return [NSString mnz_stringFromTimeInterval:durationSeconds];
}

- (NSString *)fileName {
    if (self.node) {
        return self.node.name;
    } else {
        return self.fileUrl.lastPathComponent;
    }
}

- (NSString *)fileFingerprint {
    NSString *fingerprint;

    if (self.node) {
        fingerprint = self.node.fingerprint;
    } else {
        fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:self.fileUrl.path];
    }
    
    return fingerprint;
}

#pragma mark - Notifications

- (void)movieFinishedCallback {
    self.endPlaying = YES;
    [self replayVideo];
}

- (void)applicationDidEnterBackground {
    if (![NSStringFromClass([UIApplication sharedApplication].windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"presentPasscodeLater"];
    }
}

- (void)checkNetworkChanges {
    if (!self.apiForStreaming || !MEGAReachabilityManager.isReachable) {
        return;
    }

    NSURL *oldFileURL = self.fileUrl;
    self.fileUrl = [self.apiForStreaming httpServerIsLocalOnly] ? [self.apiForStreaming httpServerGetLocalLink:self.node] : [[self.apiForStreaming httpServerGetLocalLink:self.node] mnz_updatedURLWithCurrentAddress];
    if (![oldFileURL isEqual:self.fileUrl]) {
        CMTime currentTime = self.player.currentTime;
        AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithURL:self.fileUrl];
        [self.player replaceCurrentItemWithPlayerItem:newPlayerItem];
        if (CMTIME_IS_VALID(currentTime)) {
            [self.player seekToTime:currentTime];
        }
    }
}

@end
