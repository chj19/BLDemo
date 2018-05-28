//
//  MEBLEModel.h
//  ABLETest
//
//  Created by WYq on 17/1/4.
//  Copyright © 2017年 wyq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


typedef struct _CHAR{
    char buff[1000];
}CHAR_STRUCT;


@interface MEBLEModel : NSObject





@property (nonatomic, strong)NSString *perUUIDstring;//每一个外设的唯一识别

@property (nonatomic, strong)NSString *name;//外设名称，也就是显示在界面的名称

//@property (nonatomic, strong)NSString *localName;//服务名称
//
@property (nonatomic, strong)NSString *RRSI;//RRSI数值


@property (nonatomic, strong)NSString *isConnect;//判断连接的设备是在联状态还是断开状态




@property (nonatomic, strong)NSString *temperature;//温度
@property (nonatomic, strong)NSString *humidity;//湿度
@property (nonatomic, strong)NSString *pressure;//气压
@property (nonatomic, strong)NSString *PM;//PM2.5
@property (nonatomic, strong)NSString *electricity;//电量



@property (nonatomic, strong)NSString *imageName;//图片本地存放名称


@end
