#import "MEGASdkManager.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation MEGASdkManager

+ (MEGASdk *)sharedMEGASdk {
    return MEGASdk.shared;
}

+ (MEGAChatSdk *)sharedMEGAChatSdk {
    return MEGAChatSdk.shared;
}

+ (MEGASdk *)sharedMEGASdkFolder {
    return MEGASdk.sharedFolderLink;
}

+ (void)deleteSharedSdks {
    [MEGAChatSdk.shared deleteMegaChatApi];
    [MEGASdk.shared deleteMegaApi];
    [MEGASdk.sharedFolderLink deleteMegaApi];
}

@end
