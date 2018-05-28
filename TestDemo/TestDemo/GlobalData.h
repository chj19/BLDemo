//
//  GlobalData.h
//  Meteorological
//
//  Created by 徐守卫 on 2017/11/23.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEBLEModel.h"

@interface GlobalData : NSObject

@property(nonatomic, strong)NSString *m_downloadUrls;
@property(nonatomic, strong)NSString *m_version;
@property(nonatomic)BOOL m_bWriteNoResponse;
@property(nonatomic)MEBLEModel *m_model;
@property(nonatomic, strong)NSString *m_uuidUpdate;
@property(nonatomic, strong)NSString *m_updateDevUUIDStr;

@property(nonatomic, strong)NSString *m_desktopIPaddrStr;
@property(nonatomic, strong)NSString *m_desktopBssidStr;

+(instancetype)shareData;

-(void)setModelData:(MEBLEModel *)model;
//-(MEBLEModel *)getModelData;
-(void)setPM25:(NSString *)pm25Str;

@end
