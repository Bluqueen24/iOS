
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackgroundUploadManager : NSObject

+ (instancetype)shared;

+ (BOOL)isBackgroundUploadEnabled;

- (void)enableBackgroundUploadIfPossible;
- (void)disableBackgroundUpload;

@end

NS_ASSUME_NONNULL_END
