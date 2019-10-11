
#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"

@implementation UIColor (MNZCategory)

#pragma mark - Objects

+ (UIColor *)mnz_mainBarsColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.whiteColor;
                } else {
                    return UIColor.mnz_grayF9F9F9;
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.blackColor;
                } else {
                    return [UIColor colorFromHexString:@"121212"];
                }
                break;
            }
        }
    } else {
        return UIColor.mnz_grayF9F9F9;
    }
}

+ (UIColor *)mnz_background {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBackgroundColor;
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_label {
    if (@available(iOS 13.0, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.darkTextColor;
    }
}

+ (UIColor *)mnz_basicButtonForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.whiteColor;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"535356"];
                } else {
                    return [UIColor colorFromHexString:@"363638"];
                }
            }
        }
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_basicButtonTextColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor colorWithWhite:1 alpha:.8];
            }
        }
    } else {
        return [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
    }
}

#pragma mark - Black

+ (UIColor *)mnz_black262626 {
    return [UIColor colorWithRed:38.0/255.0 green:38.0/255.0 blue:38.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_black333333 {
    return [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_black151412_09 {
    return [UIColor colorWithRed:0.08 green:0.08 blue:0.07 alpha:0.9];
}

+ (UIColor *)mnz_black000000_01 {
    return [UIColor colorWithRed:0.0  green:0.0  blue:0.0 alpha:0.100];
}

#pragma mark - Blue

+ (UIColor *)mnz_chatBlueForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"007FB9"];
                } else {
                    return [UIColor colorFromHexString:@"009AE0"];
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"059DE2"];
                } else {
                    return [UIColor colorFromHexString:@"13B2FA"];
                }
                break;
            }
        }
    } else {
        return [UIColor colorFromHexString:@"009AE0"];
    }
}

+ (UIColor *)mnz_blue007AFF {
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

+ (UIColor *)mnz_blue2BA6DE {
    return [UIColor colorWithRed:43.0/255.0 green:166.0/255.0 blue:222.0/255.0 alpha:1.0];
}

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"3D3D3D"];
                } else {
                    return [UIColor colorFromHexString:@"515151"];
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"E5E5E5"];
                } else {
                    return [UIColor colorFromHexString:@"D1D1D1"];
                }
                break;
            }
        }
    } else {
        return [UIColor colorFromHexString:@"515151"];
    }
}

+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"676767"];
                } else {
                    return [UIColor colorFromHexString:@"848484"];
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"C9C9C9"];
                } else {
                    return [UIColor colorFromHexString:@"B5B5B5"];
                }
                break;
            }
        }
    } else {
        return [UIColor colorFromHexString:@"848484"];
    }
}

+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"949494"];
                } else {
                    return [UIColor colorFromHexString:@"BBBBBB"];
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F4F4F4"];
                } else {
                    return [UIColor colorFromHexString:@"E2E2E2"];
                }
                break;
            }
        }
    } else {
        return [UIColor colorFromHexString:@"BBBBBB"];
    }
}

+ (UIColor *)mnz_chatGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F2F2F2"];
                } else {
                    return UIColor.mnz_grayEEEEEE;
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"3F3F42"];
                } else {
                    return [UIColor colorFromHexString:@"2C2C2E"];
                }
                break;
            }
        }
    } else {
        return UIColor.mnz_grayEEEEEE;
    }
}

+ (UIColor *)mnz_gray666666 {
    return [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_gray777777 {
    return [UIColor colorWithRed:119.0/255.0 green:119.0/255.0 blue:119.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_gray999999 {
    return [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayCCCCCC {
    return [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayD8D8D8 {
    return [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1.0];
}

+ (UIColor *)mnz_grayE2EAEA {
    return [UIColor colorWithRed:0.89f green:0.92f blue:0.92f alpha:1.0];
}

+ (UIColor *)mnz_grayE3E3E3 {
    return [UIColor colorWithRed:227.0/255.0 green:227.0/255.0 blue:227.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayEEEEEE {
    return [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayFAFAFA {
    return [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayFCFCFC {
    return [UIColor colorWithRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF7F7F7 {
    return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF9F9F9 {
    return [UIColor colorWithRed:249.0/255.0 green:249.0/255.0 blue:249.0/255.0 alpha:1.0];
}

#pragma mark - Green

+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"347467"];
                } else {
                    return [UIColor colorFromHexString:@"00A886"];
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"00E9B9"];
                } else {
                    return [UIColor colorFromHexString:@"00C29A"];
                }
                break;
            }
        }
    } else {
        return [UIColor colorFromHexString:@"00A886"];
    }
}

+ (UIColor *)mnz_green00897B {
    return [UIColor colorWithRed:0.0f green:0.54 blue:0.48 alpha:1.0f];
}

+ (UIColor *)mnz_green00BFA5 {
    return [UIColor colorWithRed:0.0f green:0.75 blue:0.65 alpha:1.0f];
}

+ (UIColor *)mnz_green13E03C {
    return [UIColor colorWithRed:19.0f / 255.0f green:224.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)mnz_green31B500 {
    return [UIColor colorWithRed:49.0/255.0 green:181.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)mnz_green899B9C {
    return [UIColor colorWithRed:0.54 green:0.61 blue:0.61 alpha:1];
}


#pragma mark - Orange

+ (UIColor *)mnz_orangeFFA500 {
    return [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)mnz_orangeFFD300 {
    return [UIColor colorWithRed:1 green:0.83 blue:0 alpha:1];
}

#pragma mark - Red

+ (UIColor *)mnz_redMainForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"CE0A11"];
                } else {
                    return UIColor.mnz_redMain;
                }
                break;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F95C61"];
                } else {
                    return [UIColor colorFromHexString:@"F7363D"];
                }
                break;
            }
        }
    } else {
        return UIColor.mnz_redMain;
    }
}

+ (UIColor *)mnz_redMain {
    return [UIColor mnz_redF30C14];
}

+ (UIColor *)mnz_redError {
    return [UIColor mnz_redD90007];
}

+ (UIColor *)mnz_redProI {
    return [UIColor mnz_redE13339];
}

+ (UIColor *)mnz_redProII {
    return [UIColor mnz_redDC191F];
}

+ (UIColor *)mnz_redProIII {
    return [UIColor mnz_redD90007];
}

+ (UIColor *)mnz_redF30C14 {
    return [UIColor colorWithRed:243.0f / 255.0f green:12.0f / 255.0f blue:20.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)mnz_redD90007 {
    return [UIColor colorWithRed:217.0/255.0 green:0.0 blue:7.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redE13339 {
    return [UIColor colorWithRed:225.0/255.0 green:51.0/255.0 blue:57.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redDC191F {
    return [UIColor colorWithRed:220.0/255.0 green:25.0/255.0 blue:31.0/255.0 alpha:1.0];
}

#pragma mark - White

+ (UIColor *)mnz_whiteFFFFFF_02 {
    return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.2];
}

#pragma mark - Utils

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    
    if([[hexString substringToIndex:1] isEqualToString:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if (![scanner scanHexInt:&rgbValue]) {
        return nil;
    }
    
    CGFloat r = (rgbValue & 0xFF0000) >> 16;
    CGFloat g = (rgbValue & 0xFF00) >> 8;
    CGFloat b = (rgbValue & 0xFF);
    
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

+ (UIColor *)mnz_colorForStatusChange:(MEGAChatStatus)onlineStatus {
    UIColor *colorForStatusChange;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            colorForStatusChange = [self mnz_gray666666];
            break;
            
        case MEGAChatStatusAway:
            colorForStatusChange = [self mnz_orangeFFA500];
            break;
            
        case MEGAChatStatusOnline:
            colorForStatusChange = [self mnz_green13E03C];
            break;
            
        case MEGAChatStatusBusy:
            colorForStatusChange = [self colorFromHexString:@"EB4444"];
            break;
            
        default:
            colorForStatusChange = nil;
            break;
    }
    
    return colorForStatusChange;
}

@end
