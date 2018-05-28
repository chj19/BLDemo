//
//  DeviceModifingView.h
//  Meteorological
//
//  Created by 徐守卫 on 2017/10/18.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol DeviceModifingViewDelegate <NSObject>

-(void)changeName:(NSString *)deviceName lost:(NSString *)lostName;
@end



@interface DeviceModifingView : UIView
@property(nonatomic, weak)id<DeviceModifingViewDelegate> delegate;

-(instancetype)initChangeNameView;
-(void)setName:(NSString *)name lost:(NSString *)lostStr;
@end
