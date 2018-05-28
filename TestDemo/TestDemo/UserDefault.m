//
//  UserDefault.m
//  Meteorological
//
//  Created by 徐守卫 on 2017/7/31.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import "UserDefault.h"
#import "CommonFunc.h"

@implementation UserDefault
+(void)setDefaultsValue
{
    NSDictionary *defaultDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                @"1", USER_RING_RECONNECT_ON, // 响铃重连
                                @"1", USER_RING_DATA_ON, // 响铃数据
                                @"1", USER_RING_LOST_ON, // 响应丢失
                                @"0", USER_DISTURB_ON, // 勿扰开关
                                @"0", USER_LOGIN, // 是否登录
                                @"", USER_LOGIN_NAME, // 登录名称
                                @"0", USER_BIND_DEVICE_NUM, // 是否绑定设备
                                @"", USER_BIND_DEVICE,
                                @"0", USER_DEV_SET_DISTURB,
                                nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDic];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+(void)setStringVaule:(id)value key:(NSString *)keyStr
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:value forKey:keyStr];
    
    [userDefault synchronize];
}


+(NSString *)getStringValue:(NSString *)keyStr
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:keyStr];
}

+(void)setIntValue:(NSInteger)nValue key:(NSString *)keyStr
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setInteger:nValue forKey:keyStr];
    
    [userDefault synchronize];
}


+(BOOL)isFirstRun
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *runStr = [userDefault stringForKey:USER_FIRST_RUN];
    
    if(runStr && [runStr isEqualToString:USER_FIRST_RUN])
    {
        return  YES;
    }
    
    return NO;
}


+(BOOL)isRingDataOn
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *ringOn = [userDefault stringForKey:USER_RING_DATA_ON];
    if ([ringOn isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}


+(BOOL)isRingReconnectOn
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *ringOn = [userDefault stringForKey:USER_RING_RECONNECT_ON];
    if ([ringOn isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}


+(BOOL)isRingLostOn
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *ringOn = [userDefault stringForKey:USER_RING_LOST_ON];
    if ([ringOn isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}


+(NSInteger)getSelectRing
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSInteger nRes = [userDefault integerForKey:USER_RING_SELECT];
    
    return nRes;
}


+(BOOL)isDisturbOn
{
    NSString *disturbStr = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DISTURB_ON];
    if ([disturbStr isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}


+(BOOL)getGuardStatus
{
    NSString *statusStr = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEV_SET_DISTURB];
    if ([statusStr isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}



+(BOOL)isLogin
{
    NSString *loginStr = [[NSUserDefaults standardUserDefaults] stringForKey:USER_LOGIN];
    if ([loginStr isEqualToString:@"1"]) {
        return YES;
    }
    
    return NO;
}


+(NSString *)getLoginName
{
    NSString *nameStr = [[NSUserDefaults standardUserDefaults] stringForKey:USER_LOGIN_NAME];
    if (nameStr && [nameStr length] > 0) {
        return nameStr;
    }
    
    return @"";
}

+(void)resetLoginStatus
{
    [UserDefault setStringVaule:@"" key:USER_ID];
    [UserDefault setStringVaule:@"0" key:USER_LOGIN];
    [UserDefault setStringVaule:@"" key:USER_LOGIN_NAME];
}


+(void)setBindDeviceNum:(NSInteger)nNum
{
    NSString *numStr = [NSString stringWithFormat:@"%ld", (long)nNum];
    [[NSUserDefaults standardUserDefaults] setObject:numStr forKey:USER_BIND_DEVICE_NUM];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)getBindNum
{
    NSString *numStr = [[NSUserDefaults standardUserDefaults] stringForKey:USER_BIND_DEVICE_NUM];
    if (numStr && [numStr length] > 0) {
        return [numStr integerValue];
    }
    
    return 0;
}

+(void)resetBoundDevice
{
    [self setBindDeviceNum:0];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:USER_BIND_DEVICE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getBoundDevice
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:USER_BIND_DEVICE];
}



+(NSString *)getUserGoodsName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:USER_GOODS_NAME];
}


+(void)saveBoundBle:(NSArray *)arr
{
    if (arr && [arr count] > 0) {
        [UserDefault setBindDeviceNum:[arr count]];
    }
    else
    {
        [UserDefault setBindDeviceNum:0];
    }
    
    NSUserDefaults *theDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *theDic = [[NSMutableDictionary alloc] init];
    [theDic setObject:arr forKey:USER_BOUND_BLE];
    
    NSString *jsonStr = [CommonFunc dictionaryToJson:theDic];
    [theDefault setObject:jsonStr forKey:USER_BOUND_BLE];
    [theDefault synchronize];
}

+(id)getBoundBle
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_BOUND_BLE];
}


+(NSString *)getDisturbStartTime
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DISTURB_TIME_S];
}

+(NSString *)getDisturbEndTime
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DISTURB_TIME_E];
}

@end
