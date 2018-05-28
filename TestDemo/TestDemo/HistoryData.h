//
//  HistoryData.h
//  Meteorological
//
//  Created by 徐守卫 on 2017/12/12.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HistoryDataMode : NSObject
{
}
@property(nonatomic, strong) NSString *m_hCRC;
@property(nonatomic, strong) NSString *m_temp;
@property(nonatomic, strong) NSString *m_humi;
@property(nonatomic, strong) NSString *m_press;
@property(nonatomic, strong) NSString *m_tCRC;
@end



@interface HistoryData : NSObject
{
    NSMutableArray *m_historyArr;
}

+(instancetype)shareInstance;

-(BOOL)addData:(NSString *)perData;
-(BOOL)isAllRight;
-(NSInteger)dataCount;
-(void)cleanData;

-(NSMutableArray *)getHisData;

@end
