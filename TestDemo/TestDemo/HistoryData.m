//
//  HistoryData.m
//  Meteorological
//
//  Created by 徐守卫 on 2017/12/12.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import "HistoryData.h"
@implementation HistoryDataMode
@synthesize m_hCRC;
@synthesize m_humi;
@synthesize m_tCRC;
@synthesize m_temp;
@synthesize m_press;
@end



@implementation HistoryData

+(instancetype)shareInstance
{
    static HistoryData *handle = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        handle = [[HistoryData alloc] init];
    });
    
    return handle;
}

-(BOOL)addData:(NSString *)perData
{

    NSMutableString *muttemStr = [NSMutableString stringWithString:perData];
    if ([muttemStr length] < 10) {
        return YES;
    }
    NSString *hCrc = [muttemStr substringWithRange:NSMakeRange(0, 1)];
    if ([hCrc isEqualToString:@"Q"] == NO) {
        return YES;
    }
    //温度
    NSString *temLabelStr = [muttemStr substringWithRange:NSMakeRange(1, 3)];
    //如果是正数去掉+号
    NSString *temLabel = [temLabelStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
    NSString *humLabelStr = [muttemStr substringWithRange:NSMakeRange(4, 2)];
    NSString *preLabelStr = [muttemStr substringWithRange:NSMakeRange(6, 3)];
    NSString *tCrc = [muttemStr substringWithRange:NSMakeRange(9, 1)];
    if ([tCrc isEqualToString:@"R"] == NO) {
        return YES;
    }
    HistoryDataMode *model = [[HistoryDataMode alloc] init];
    
    model.m_temp = temLabel;
    model.m_humi = humLabelStr;
    model.m_press = preLabelStr;
    model.m_hCRC = hCrc;
    model.m_tCRC = tCrc;
    
    if (!m_historyArr) {
        m_historyArr = [[NSMutableArray alloc] init];
    }
    
    [m_historyArr addObject:model];
    
    return NO;
}

-(NSMutableArray *)getAllData
{
    return m_historyArr;
}


-(NSInteger)dataCount
{
    return [m_historyArr count];
}



-(NSMutableArray *)getHisData
{
    return m_historyArr;
}

-(void)cleanData
{
    if (m_historyArr) {
        [m_historyArr removeAllObjects];
    }
}

-(BOOL)isAllRight
{
    if (m_historyArr) {
        NSInteger nCount = [m_historyArr count];
        for (NSInteger i = 0; i < nCount; i++) {
            HistoryDataMode *theData = [m_historyArr objectAtIndex:i];
            if ([theData.m_hCRC isEqualToString:@"51"] == NO || [theData.m_tCRC isEqualToString:@"52"] == NO) {
                return NO;
            }
        }
        return YES;
    }
    
    return NO;
}


@end
