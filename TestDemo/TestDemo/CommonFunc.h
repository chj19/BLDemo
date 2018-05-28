//
//  CommonFunc.h
//  PortableWeather
//
//  Created by 徐守卫 on 2017/6/30.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, hourType)
{
    hourTemp,
    hourHumi,
    hourAir,
    hourPressue,
    hourMax,
};


@interface CommonFunc : NSObject

+(id)shareInstance;


//通过颜色来生成一个纯色图片
+(UIImage *)imageFromColor:(UIColor *)color frame:(CGRect)frame;

//字符串转颜色
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert alpha:(CGFloat)fAlpha;

+ (NSString *)stringFromHexString:(NSString *)hexString;

+ (NSString *)stringToHex:(NSString *)string;

+ (NSString *)transform:(NSString *)chinese;


// 跳转到设置蓝牙页面
+(void)jumpToSettingBluetooth;
+(void)jumpToSettingTemp;
+(void)jumpToSettingGPS;
+(void)jumpToAppSetting;

+(NSString *)emojiEncode:(NSString *)emojiStr;
+(NSString *)emojiDecode:(NSString *)encodedStr;


// 温度
+(NSString *)getTemperatureString:(NSInteger) nTemp space:(BOOL)bWithSpace;

// 时间
+(NSInteger)getDataComponents:(NSCalendarUnit)unit;
+(NSString *)getCurrentTimeString;
+(NSString *)getTodayStr;

// 沙盒图片
+(void)saveImageDocuments:(UIImage *)image path:(NSString *)imageName;
+(void)saveImageDocuments:(UIImage *)image;
+(BOOL)deleteImageDocuments;
+(UIImage *)getDocumentImage;
+(UIImage *)getDocumentImage:(NSString *)imageName;


// json -> string
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+ (NSString*)dictionaryToJson:(NSDictionary *)dic;


+(UIFont *)getBoldFontWithPixel:(NSInteger)nPixel;
+(UIFont *)getFontWithPixel:(NSInteger)nPixel;

//获取气象日历数据
+ (NSString *)getimageUrlWithString:(BOOL)bLeft;
+(NSString *)getDateString;
+(BOOL)isLaterTime:(NSInteger)theHour min:(NSInteger)theMin compareHour:(NSInteger)compareHour compareMin:(NSInteger)compareMin;
+(BOOL)isDisturbTime;

+(NSInteger)getNavHeight;

// 显示定义的消息
+(void)showErrorMsg:(NSString *)msgStr parent:(UIViewController *)ctrl;

+(void)setNavTitle:(NSString *)titleStr nav:(UINavigationController *)navCtrl;

+(int)checkIsHaveNumAndLetter:(NSString*)checkStr;


+(CGSize)getTextSize:(NSString *)string size:(CGSize)scopeSize fontSize:(NSInteger)size;

+(BOOL)isSmallScreen;

+(NSDictionary *)getVersion;
@end
