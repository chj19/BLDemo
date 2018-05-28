//
//  UserDefault.h
//  Meteorological
//
//  Created by 徐守卫 on 2017/7/31.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>


#define USER_FIRST_RUN       @"FirstRun"

#define USER_RING_DATA_ON           @"DataOn"
#define USER_RING_RECONNECT_ON      @"ReconnectOn"
#define USER_RING_LOST_ON           @"LostOn"
#define USER_RING_SELECT          @"SELECTRING"

#define USER_FRST_RUN               @"AppFirstRun"
#define USER_LOGIN                  @"UserLogin"
#define USER_LOGIN_NAME             @"LoginName"
#define USER_ID                     @"UserID"
#define USER_GENDER                 @"UserGender"

#define USER_BIND_DEVICE_NUM            @"BindDeviceNum"
#define USER_BIND_DEVICE            @"BindDevice"
#define USER_GOODS_NAME             @"BoundGoodsName"

#define USER_BOUND_BLE              @"BoundBLEDevice"

#define USER_CITY                   @"city"

// 勿扰开关和开始结束时间
#define USER_DEV_SET_DISTURB        @"DEV_SET_DISTURB"
#define USER_DISTURB_ON             @"DISTURBON"
#define USER_DISTURB_TIME_S         @"DisturbStartTime"
#define USER_DISTURB_TIME_E         @"DisturbEndtime"


#define USER_FIRMWARE_VERSION       @"FIRAMWARE_VERSION"

#define USER_DESK_IP        @"DESK_IP_ADDRESS"
#define TIME_OUT            10


@interface UserDefault : NSObject
+(void)setDefaultsValue;

+(void)setStringVaule:(id)value key:(NSString *)keyStr;
+(void)setIntValue:(NSInteger)nValue key:(NSString *)keyStr;
+(NSString *)getStringValue:(NSString *)keyStr;

+(BOOL)isFirstRun;
+(BOOL)isRingDataOn;
+(BOOL)isRingReconnectOn;
+(BOOL)isRingLostOn;

+(BOOL)isDisturbOn;
+(BOOL)getGuardStatus;

+(NSInteger)getSelectRing;

+(BOOL)isLogin;
+(NSString *)getLoginName;
+(void)resetLoginStatus;

+(void)setBindDeviceNum:(NSInteger)nNum;
+ (NSInteger)getBindNum;

+(NSString *)getBoundDevice;
+(void)resetBoundDevice;

+(NSString *)getUserGoodsName;

+(void)saveBoundBle:(NSArray *)arr;
+(id)getBoundBle;

+(NSString *)getDisturbStartTime;
+(NSString *)getDisturbEndTime;

@end
