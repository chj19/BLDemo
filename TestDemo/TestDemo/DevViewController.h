//
//  DevViewController.h
//  TestDemo
//
//  Created by 徐守卫 on 2018/4/8.
//  Copyright © 2018年 徐守卫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"

@interface DevViewController : UIViewController

-(instancetype)initWith:(NSDictionary *)peripheralDic;
@end
