//
//  CommonFunc.m
//  PortableWeather
//
//  Created by 徐守卫 on 2017/6/30.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonFunc.h"
#import <sys/utsname.h>
//#import "UserDefault.h"
#import "ConstDefine.h"

@implementation CommonFunc

+(id)shareInstance
{
    static dispatch_once_t pred;
    static CommonFunc *handle;
    dispatch_once(&pred, ^{
        handle = [[CommonFunc alloc] init];
    });
    
    return handle;
}



//通过颜色来生成一个纯色图片
+(UIImage *)imageFromColor:(UIColor *)color frame:(CGRect)frame
{
    CGRect rect = frame;//CGRectMake(0, 0, frame.size.width, frame.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}


//字符串转颜色
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert
{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    
    if ([cString length] < 6)
        return [UIColor whiteColor];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor whiteColor];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

+ (UIColor *) colorWithHexString: (NSString *) stringToConvert alpha:(CGFloat)fAlpha
{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    
    if ([cString length] < 6)
        return [UIColor whiteColor];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor whiteColor];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:fAlpha];
}

//十六进制的字符串To String
+ (NSString *)stringFromHexString:(NSString *)hexString
{
    
    //    for(NSString * toRemove in [NSArray arrayWithObjects:@" ",@"\r", nil])
    //        hexString = [hexString stringByReplacingOccurrencesOfString:toRemove withString:@""];
    
    // The hex codes should all be two characters.
    
    if (([hexString length] % 2) != 0)
        return nil;
    
    NSMutableString *string = [NSMutableString string];
    
    for (NSInteger i = 0; i < [hexString length]; i += 2) {
        
        NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSInteger decimalValue = 0;
        sscanf([hex UTF8String], "%x", (unsigned int *)&decimalValue); // modified by xsw 20170220
        [string appendFormat:@"%c", (int)decimalValue]; // modified by xsw 20170220
    }
    return string;
    
    
    
    /*
     
     char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
     bzero(myBuffer, [hexString length] / 2 + 1);
     for (int i = 0; i < [hexString length] - 1; i += 2) {
     unsigned int anInt;
     NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
     NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr] ;
     [scanner scanHexInt:&anInt];
     myBuffer[i / 2] = (char)anInt;
     }
     NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
     NSLog(@"------字符串=======%@",unicodeString);
     return unicodeString;
     
     */
}

//string To十六进制字符串
+ (NSString *)stringToHex:(NSString *)string
{
    
    NSString * hexStr = [NSString stringWithFormat:@"%@",
                         [NSData dataWithBytes:[string cStringUsingEncoding:NSUTF8StringEncoding]
                                        length:strlen([string cStringUsingEncoding:NSUTF8StringEncoding])]];
    
    for(NSString * toRemove in [NSArray arrayWithObjects:@"<", @">", nil])
        hexStr = [hexStr stringByReplacingOccurrencesOfString:toRemove withString:@""];
    return hexStr;
}


- (NSData *)convertHexStrToString:(NSString *)str {
    
    NSString *hexString = str;
    
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
//        DLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:1];
    return newData;
}
- (NSString *)dataToString:(NSData *)data
{
    
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff]; ///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
    
    
    return hexStr;
}
//汉字转拼音
+ (NSString *)transform:(NSString *)chinese
{
    NSMutableString *pinyin = [chinese mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    DLog(@"%@", pinyin);
    return pinyin;
}



+(void)jumpToSettingBluetooth
{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
#if 1
    /*Wi-Fi: App-Prefs:root=WIFI
    蓝牙: App-Prefs:root=Bluetooth
    蜂窝移动网络: App-Prefs:root=MOBILE_DATA_SETTINGS_ID
    个人热点: App-Prefs:root=INTERNET_TETHERING
    运营商: App-Prefs:root=Carrier
    通知: App-Prefs:root=NOTIFICATIONS_ID
    通用: App-Prefs:root=General
    通用-关于本机: App-Prefs:root=General&path=About
    通用-键盘: App-Prefs:root=General&path=Keyboard
    通用-辅助功能: App-Prefs:root=General&path=ACCESSIBILITY
    通用-语言与地区: App-Prefs:root=General&path=INTERNATIONAL
    通用-还原: App-Prefs:root=Reset
    墙纸: App-Prefs:root=Wallpaper
Siri: App-Prefs:root=SIRI
    隐私: App-Prefs:root=Privacy
    定位: App-Prefs:root=LOCATION_SERVICES
Safari: App-Prefs:root=SAFARI
    音乐: App-Prefs:root=MUSIC
    音乐-均衡器: App-Prefs:root=MUSIC&path=com.apple.Music:EQ
    照片与相机: App-Prefs:root=Photos
FaceTime: App-Prefs:root=FACETIME*/
    NSURL *url = [NSURL URLWithString:@"App-Prefs:root=Bluetooth"];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
#endif
}

+(void)jumpToSettingGPS
{
    NSURL *url = [NSURL URLWithString:@"App-Prefs:root=LOCATION_SERVICES"];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}
+(void)jumpToSettingTemp
{
    if ([[UIDevice currentDevice]systemVersion].floatValue>=10.0) {
        // iOS10之后不允许跳转到设置的子页面，只允许跳转到设置界面(首页)，据说跳转到系统设置子页面，但同时会加大遇到审核被拒的可能性
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else {
        NSURL *url = [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}


+(void)jumpToAppSetting
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}

+(NSString *)emojiEncode:(NSString *)emojiStr
{
    NSString *uniStr = [NSString stringWithUTF8String:[emojiStr UTF8String]];
    NSData *tmpData = [uniStr dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    NSString *encodeStr = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
    DLog(@"encodeStr: %@", encodeStr);
    return encodeStr;
}

+(NSString *)emojiDecode:(NSString *)encodedStr
{
    const char *jsonString = [encodedStr UTF8String];
    NSData *jsonData = [NSData dataWithBytes:jsonString length:strlen(jsonString)];
    NSString *emojiStr = [[NSString alloc] initWithData:jsonData encoding:NSNonLossyASCIIStringEncoding];
    DLog(@"emojiStr: %@", emojiStr);
    return emojiStr;
}



+(NSString *)getTemperatureString:(NSInteger) nTemp space:(BOOL)bWithSpace
{
    if (bWithSpace) {
        return [NSString stringWithFormat:@"%ld %@", (long)nTemp, STR_DEF_TEMP_UNIT];
    }
    
    return [NSString stringWithFormat:@"%ld%@", (long)nTemp, STR_DEF_TEMP_UNIT];
}



//保存图片
+(void)saveImageDocuments:(UIImage *)image
{
    UIImage *imagesave = image;
    NSString *path_sandox = NSHomeDirectory();
    NSString *imagePath = [path_sandox stringByAppendingString:@"/Documents/background.png"];
    [UIImagePNGRepresentation(imagesave) writeToFile:imagePath atomically:YES];
}

+(BOOL)deleteImageDocuments
{
    NSString *sandboxPath = NSHomeDirectory();
    NSString *iamgePath = [sandboxPath stringByAppendingString:@"/Documents/background.png"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:iamgePath]) {
        NSError *err = nil;
        BOOL bRemoved = [fileManager removeItemAtPath:iamgePath error:&err];
       
        return bRemoved;
    }
    
    return NO;
}


+(void)saveImageDocuments:(UIImage *)image path:(NSString *)imageName
{
    UIImage *imagesave = image;
    NSString *path_sandox = NSHomeDirectory();
    NSString *pathStr = [NSString stringWithFormat:@"/Documents/%@", imageName];
    NSString *imagePath = [path_sandox stringByAppendingString:pathStr];
    [UIImagePNGRepresentation(imagesave) writeToFile:imagePath atomically:YES];
}


+(UIImage *)getDocumentImage
{
    NSString *aPath3=[NSString stringWithFormat:@"%@/Documents/%@.png",NSHomeDirectory(),@"background"];
    UIImage *imgFromUrl3=[[UIImage alloc]initWithContentsOfFile:aPath3];
    // 图片保存相册
//    UIImageWriteToSavedPhotosAlbum(imgFromUrl3, self, nil, nil);
    return imgFromUrl3;
}

+(UIImage *)getDocumentImage:(NSString *)imageName
{
    NSString *aPath3=[NSString stringWithFormat:@"%@/Documents/%@",NSHomeDirectory(), imageName];
    UIImage *imgFromUrl3=[[UIImage alloc]initWithContentsOfFile:aPath3];
    // 图片保存相册
    //    UIImageWriteToSavedPhotosAlbum(imgFromUrl3, self, nil, nil);
    return imgFromUrl3;
}

//json格式字符串转字典：

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        
        return nil;
        
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        
        DLog(@"json解析失败：%@",err);
        
        return nil;
        
    }
    
    return dic;
    
}

//字典转json格式字符串：

+ (NSString*)dictionaryToJson:(NSDictionary *)dic

{
    
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}


+(UIFont *)getBoldFontWithPixel:(NSInteger)nPixel
{
    CGFloat fSize = (nPixel / 2.0 / 96.0) * 72.0;
    return [UIFont boldSystemFontOfSize:fSize];
}


+(UIFont *)getFontWithPixel:(NSInteger)nPixel
{
    CGFloat fSize = (nPixel / 2.0 / 96.0) * 72.0;
    return [UIFont systemFontOfSize:fSize];
}



+ (NSString *)getimageUrlWithString:(BOOL)bLeft
{
    //    NSString *urlStr = @"http://123.207.173.111/PWS/images/calendar/";
    
    NSMutableString *urlStr = [NSMutableString stringWithString:@"http://123.207.173.111/PWS/images/calendar/"];
    
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd"];
    NSString *date1 = [dateformatter stringFromDate:nowDate];
    
    [urlStr appendString:date1];
    
    if (bLeft) {
        [urlStr appendString:@"L.jpg"];
    }
    else
    {
        [urlStr appendString:@"R.jpg"];
    }
    
    return urlStr;
}

+(NSInteger)getNavHeight
{
    UIDevice *thePhone = [UIDevice currentDevice];
    DLog(@"systemVersion: %@", thePhone.systemVersion);
    DLog(@"systemName: %@", thePhone.systemName);
    DLog(@"name: %@", thePhone.name);
    DLog(@"model: %@", thePhone.model);
    DLog(@"localizedModel: %@", thePhone.localizedModel);

    [CommonFunc getDeviceVersionInfo];
    
    if (@available(iOS 11.0, *)) {
        DLog(@"safeArea = %@", NSStringFromUIEdgeInsets([[UIApplication sharedApplication] keyWindow].safeAreaInsets));
    }
    
    DLog(@"%@", NSHomeDirectory());
    return [thePhone.systemVersion integerValue];
}

+ (NSString *)getDeviceVersionInfo
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithFormat:@"%s", systemInfo.machine];
//__IPHONE_11_0
    DLog(@"iPhone : %@", platform);
    return platform;
}

//
+(void)showErrorMsg:(NSString *)msgStr parent:(UIViewController *)ctrl
{
    NSString *title = ctrl.title;
    NSString *message = msgStr;
    NSString *cancelButtonTitle = @"OK";
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
//        NSLog(@"The \"Okay/Cancel\" alert's cancel action occured.");
    }];
    
    
    // Add the actions.
    [alertController addAction:cancelAction];
    
    [ctrl presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - date
+(NSString *)getTodayStr
{
    NSDate *curDate = [NSDate date];
    if (curDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSString *timeStr = [dateFormatter stringFromDate:curDate];
        return timeStr;
    }
    
    return nil;
}
// yyyy-MM-dd HH:mm:ss
+(NSString *)getCurrentTimeString// 获取当前时间戳
{
    NSDate *curDate = [NSDate date];
    if (curDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *timeStr = [dateFormatter stringFromDate:curDate];
        return timeStr;
    }
    
    return nil;
}

+(NSString *)getDateString
{
    NSInteger nMonth = [CommonFunc getDataComponents:NSCalendarUnitMonth];
    NSInteger nDay = [CommonFunc getDataComponents:NSCalendarUnitDay];
    NSString *dayStr = [NSString stringWithFormat:@"%ld月%ld日", (long)nMonth, (long)nDay];
    NSInteger nWeek = [CommonFunc getDataComponents:NSCalendarUnitWeekday];
    switch (nWeek) {
        case 2:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期一"];
            break;
        case 3:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期二"];
            break;
        case 4:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期三"];
            break;
        case 5:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期四"];
            break;
        case 6:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期五"];
            break;
        case 7:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期六"];
            break;
        case 1:
            return [NSString stringWithFormat:@"%@ %@", dayStr, @"星期日"];
            break;
        default:
            break;
    }
    
    return @"";
}


+(BOOL)isLaterTime:(NSInteger)theHour min:(NSInteger)theMin compareHour:(NSInteger)compareHour compareMin:(NSInteger)compareMin
{
    if (theHour > compareHour) {
        return YES;
    }
    
    if (theHour < compareHour) {
        return NO;
    }
    
    if (theHour == compareHour) {
        if (theMin > compareMin) {
            return YES;
        }
        return NO;
    }
    
    return NO;
}

+(void)setNavTitle:(NSString *)titleStr nav:(UINavigationController *)navCtrl
{
    UILabel *titleLabel = [navCtrl.navigationBar viewWithTag:NAV_TITLE_LABEL];
    if (titleLabel) {
        titleLabel.text = titleStr;
    }
}


+(NSInteger)getDataComponents:(NSCalendarUnit)unit
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unit fromDate:date];
    
    switch (unit) {
        case NSCalendarUnitYear:
            return [components year];
            break;
        case NSCalendarUnitMonth:
            return [components month];
            break;
        case NSCalendarUnitDay:
            return [components day];
            break;
        case NSCalendarUnitHour:
            return [components hour];
            break;
        case NSCalendarUnitMinute:
            return [components minute];
            break;
        case NSCalendarUnitSecond:
            return [components second];
            break;
        case NSCalendarUnitWeekday:
//            components weekdayOrdinal
//            return [calendar ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitDay forDate:date];
            return [components weekday];
            break;
        default:
            break;
    }
    
    return NSNotFound;
}



+(BOOL)isSmallScreen
{
    return (SCREEN_W <= 320);
}


+(int)checkIsHaveNumAndLetter:(NSString*)checkStr
{
    //数字条件
    NSRegularExpression *tNumRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合数字条件的有几个字节
    NSUInteger tNumMatchCount = [tNumRegularExpression numberOfMatchesInString:checkStr
                                                                       options:NSMatchingReportProgress
                                                                         range:NSMakeRange(0, checkStr.length)];
    
    //英文字条件
    NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合英文字条件的有几个字节
    NSUInteger tLetterMatchCount = [tLetterRegularExpression numberOfMatchesInString:checkStr options:NSMatchingReportProgress range:NSMakeRange(0, checkStr.length)];
    

    return (int)(tNumMatchCount + tLetterMatchCount);
}

#pragma mark - Text Size


+(NSDictionary *)getVersion
{
//获得应用的Verison号:
    NSString *versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

//获得build号:
   NSString *buildStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSMutableDictionary *retDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:GET(versionStr), @"version", GET(buildStr), @"build", nil];
    return retDic;
}

@end
