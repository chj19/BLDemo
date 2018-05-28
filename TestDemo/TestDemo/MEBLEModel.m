//
//  MEBLEModel.m
//  ABLETest
//
//  Created by WYq on 17/1/4.
//  Copyright © 2017年 wyq. All rights reserved.
//

#import "MEBLEModel.h"

@implementation MEBLEModel
@synthesize perUUIDstring;//每一个外设的唯一识别
@synthesize name;//外设名称，也就是显示在界面的名称
@synthesize RRSI;//RRSI数值
@synthesize isConnect;//判断连接的设备是在联状态还是断开状态
@synthesize temperature;//温度
@synthesize humidity;//湿度
@synthesize pressure;//气压
@synthesize PM;//PM2.5
@synthesize electricity;//电量
@synthesize imageName;//图片本地存放名称

@end
