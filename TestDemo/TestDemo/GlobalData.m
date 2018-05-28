//
//  GlobalData.m
//  Meteorological
//
//  Created by 徐守卫 on 2017/11/23.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import "GlobalData.h"

@implementation GlobalData
@synthesize m_version;
@synthesize m_downloadUrls;
@synthesize m_model;
@synthesize m_uuidUpdate;
@synthesize m_bWriteNoResponse;
@synthesize m_updateDevUUIDStr;
// 
@synthesize m_desktopBssidStr;
@synthesize m_desktopIPaddrStr;

+(instancetype)shareData
{
    static GlobalData *hanle = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hanle = [[GlobalData alloc] init];
    });
    
    return hanle;
}

-(void)setPM25:(NSString *)pm25Str
{
    if (!m_model) {
        m_model = [[MEBLEModel alloc] init];
    }
    
    m_model.PM = [NSString stringWithFormat:@"%@", GET(pm25Str)];
}

-(void)setModelData:(MEBLEModel *)model
{
    if (!m_model) {
        m_model = [[MEBLEModel alloc] init];
    }
    
//    @synthesize temperature;//温度
//    @synthesize humidity;//湿度
//    @synthesize pressure;//气压
//    @synthesize PM;//PM2.5
//    @synthesize electricity;//电量
    m_model.temperature = [NSString stringWithFormat:@"%@", model.temperature];
    m_model.humidity = [NSString stringWithFormat:@"%@", model.humidity];
    m_model.pressure = [NSString stringWithFormat:@"%@", model.pressure];
    m_model.electricity = [NSString stringWithFormat:@"%@", model.electricity];
}



@end
