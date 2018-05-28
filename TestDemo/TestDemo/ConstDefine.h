//
//  ConstDefine.h
//  TestDemo
//
//  Created by 徐守卫 on 2018/4/4.
//  Copyright © 2018年 徐守卫. All rights reserved.
//

#ifndef ConstDefine_h
#define ConstDefine_h

#define IPHONE_X_VIEW       0// iPhoneX

#define STR_NULL        @""
#define GET(str)                    ((str && NO == [str isKindOfClass:[NSNull class]] && NO == [@"(null)" isEqualToString:str])? str : @"")

#define ISEMPTY(str)                (((str == nil)|| [str isEqualToString:STR_NULL]) ? YES : NO || ([str length] == 0) )


#define SCREEN_W    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_H    [[UIScreen mainScreen] bounds].size.height

#define IPHONEX_OFFSET          20
#define STATUS_BAR_HEIGHT       (IPHONE_X_VIEW ? 40:20)
#define SCREEN_NAV_H            (IPHONE_X_VIEW ? 84 : 64)
#define VIEW_HEIGHT         (SCREEN_H - SCREEN_NAV_H)


#pragma mark - string
#define STR_DEF_TEMP_UNIT       @"°C"
#define STR_DEF_HUMI_UNIT       @"%"
#define STR_DEF_PM25_UNIT       @"μg/m³"
#define STR_DEF_PRESSURE_UNIT   @"HPA"


#pragma mark - Notification
#define NOTI_OPEN_LEFTVIEW    @"OPEN_LEFTVIEW"
#define NOTI_BLE_STATUS     @"BLE_STATUS"
#define NOTI_LEFT_SIDE          @"LeftSideNotification"
#define NOTI_PM25           @"GETED_PM25"
#define NOTI_SET_RING_SUC       @"SET_RING_SUC"
#define NOTI_PROGRESS           @"UPDATE_PROGRESS"
#define NOTI_UPDATE_STATUS      @"UPDATE_STATUS"
#define NOTI_DISTURB_CHANGED        @"CHANGE_DISTURB"
#define NOTI_HISTORY_DATA_READY     @"HISTORY_DATA_READY"
#define NOTI_VOL_UPDATE                @"VOL_UPDATE"
#define NOTI_DEV_CANCEL_CALL        @"DEV_CANCEL_CALL"

#define COLOR_TRANCLUCENT_BACKGROUND_LIGHT        [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.3] // 半透明背景色

#define NAV_TITLE_LABEL  110000
///////////////////////////////////////////////

#define DEF_BLE_GETDATA_REQ         @"01" //APP向设备发出上传数据请求    0x01

#define DEF_BLE_CALL_REQ      @"aa" //寻物请求    0xaa      APP寻找设备

#define DEF_BLE_CALL_RES    @"ab" //APP找到设备/设备找到APP    0xab    APP找到设备后响应设备

#define DEF_BLE_UNBIND_REQ      @"CC" //APP解绑    0xCC    APP要求解绑设备

#define DEF_BLE_BIND_REQ        @"FF" //绑定请求    0xFF

#define DEF_BLE_OPEN_MANAGER_REQ    @"F1" //开启看管指令    0xF1
#define DEF_BLE_CLOSE_MANAGER_REQ   @"AC" //关闭看管指令    0xAC

#define DEF_BLE_OPEN_DISTURB_REQ    @"F2" //开启勿扰模式    0xF2

#define DEF_BLE_CLOSE_DISTUREB_REQ  @"F3" //关闭勿扰模式    0xF3

#define DEF_BLE_MODIFY_NAME_REQ     @"F4" //修改蓝牙名称请求    0xF4
#define DEF_BLE_CHECK_CODE_STA      @"F1" //校验码头    0xF5
#define DEF_BLE_CHECK_CODE_END      @"1F" //校验码尾 0xF6

#define DEF_BLE_RESPONSE        @"F7"   //收到请求响应    0xF7
#define DEF_BLE_VERSION_REQ     @"F8"   //设备版本获取 0xF8
#define DEF_BLE_RING1_REQ       @"F9"//铃声1设置    0xF9
#define DEF_BLE_RING2_REQ       @"FA"//铃声2设置    0xFA
#define DEF_BLE_RING3_REQ       @"FB"//铃声3设置    0xFB

/////////////////////////////////////////
#define DEF_DEV_VOL         @"F0"//电量识别码图    0xF0
#define DEF_DEV_CALL        @"aa"//设备寻找APP    0xaa    设备查找APP
#define DEF_DEV_PAIR_FAILED     @"cd"//APP与设备匹配失败    0xcd    设备已被其他APP绑定
#define DEF_DEV_LOW_POWER       @"0xEE"//设备电量低报警    0xEE    设备向APP发送低电压状态
#define DEF_DEV_MODIFY_NAME_SUC     @"f9"   //修改名称成功    0xF9
#define DEF_DEV_MODIFY_NAME_FAILD   @"f8"//修改名称失败    0xF8
#define DEF_DEV_BIND_SUC        @"ef"//绑定成功    0xFB

#define DEF_DEV_NO_AUTH         @"BB"
#define DEF_DEV_BIND_FAILED     @"CD"//绑定失败 0xFA
#define DEF_DEV_OPEN_MANAGER_SUC @"F7" //开启看管成功  0xF7
#define DEF_DEV_OPEN_MANAGER_FAILED     @"F6"//开启看管失败    0xF6
#define DEF_DEV_VER         @"02"   //设备版本号 0x02    二期为0x02,
#define DEF_DEV_DISTURB_OP_SUC  @"F5"   //开启/关闭勿扰成功    0xF5
#define DEF_DEV_DISTURB_OP_FAILED   @"F4"   //开启关闭/勿扰失败 0xF4
#define DEF_DEV_RING_OP_SUC         @"F3"   //铃声设置成功 0xF3
#define DEF_DEV_SET_RING1_SUC       @"11"
#define DEF_DEV_SET_RING2_SUC       @"12"
#define DEF_DEV_SET_RING3_SUC       @"13"
#define DEF_DEV_RING_OP_FAILED      @"F2"   // 铃声设置失败 0xF2
#define DEF_DEV_RESPONSE            @"F7"
//////////////////////////////////////////////

#endif /* ConstDefine_h */
