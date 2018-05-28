//
//  BLEManager.m
//  BeeStarDemo
//
//  Created by 徐守卫 on 2017/3/6.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import "BLEManager.h"
#import "MEBLEModel.h"
#import "CommonFunc.h"
#import "BleCodeDefine.h"
#import "ConstDefine.h"
#import "UserDefault.h"
#import "BoundDeviceManager.h"
//#import "DataUpload.h"
//#import "fileManager.h"
#import "HistoryData.h"
#import "GlobalData.h"
#import "ParamaterStorage.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif


#define UIALERTVIEW_TAG_REBOOT 1

#define USED_CODE_TEMP_CLOSED       0



@interface BLEManager()<BoundDeviceManagerDelegate>
{
    CBCentralManager *m_central;
    NSDictionary *m_curAdDataDic;// 当前连接设备的广播数据，用于获取设备广播名称
    CBPeripheral *m_curPeripheral; // 当前正在操作的设备
    NSMutableArray *m_boundUUIDArr;

    NSMutableArray *m_activeCharacteristics;   //当前正在操作的特征值缓存
    NSMutableArray *m_activeDescriptors;   //当前正在操作的特征值缓存

    NSArray *m_peripheralArr;
    BOOL m_bNeedPowerOn;
    
    BOOL m_bResponse;
    BOOL m_bCharacteristicsE5Finished;
    BOOL m_bCharacteristicsE4Finished;
    
    NSString *m_mode;
    NSString *m_devNewName;
    NSString *m_bindNewName;
    
//    NSInteger m_nDeviceVer;
    BoundDeviceManager *m_boundDeviceManager;
    
    BOOL m_bUpgrade; // 用于标识当前正处于固件升级状态
    int step, nextStep;
    int expectedValue;
    int chunkSize;
    int blockStartByte;
    ParamaterStorage *storage;
    NSMutableData *fileData;
    
    BOOL m_bWriteNoReponse;
    BOOL m_bSendGuard; // 当前发送的命令是开启或关闭勿扰功能
    BOOL m_bGetHistory;
}

@end




@implementation BLEManager
@synthesize m_delegate;
@synthesize m_linkStatus;
@synthesize m_bEnterBackgroud;
@synthesize m_bDeleteDevice;
@synthesize m_requireDelegate;
@synthesize blockSize;

+(instancetype)ShareInstance
{
    static BLEManager *handle = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        handle = [[BLEManager alloc] initData];
    });
    
    return handle;
}


-(instancetype)initData
{
    self = [[BLEManager alloc] init];
    m_boundDeviceManager = [[BoundDeviceManager alloc] init];
    [m_boundDeviceManager getBoundDeviceFromDefault];
    m_boundDeviceManager.m_delegate = self;
    return self;
}


-(BOOL)isPowerOn
{
    return !m_bNeedPowerOn;
}


-(void)initManager
{
    if (!m_central) {
//        m_central = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{ CBCentralManagerOptionRestoreIdentifierKey:
//                                                                                             @"MeteCentralManagerIdentifier" }];
        m_central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    NSString *boundStr = [UserDefault getBoundDevice];
    if (boundStr && [boundStr length] > 0) {
        NSArray *tmpArr = [boundStr componentsSeparatedByString:@","];
        if (tmpArr && [tmpArr count] > 0) {
            m_boundUUIDArr = [[NSMutableArray alloc] initWithArray:tmpArr];
        }
    }
    
    m_bEnterBackgroud = YES;
    m_bWriteNoReponse = YES;// Demo 默认为YES
}


-(BOOL)isScaning
{
    return m_central.isScanning;
}

#if 0
-(void)startScan
{
    if (NO == m_central.isScanning) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_10_0
        if (m_central.state != CBManagerStatePoweredOn)
#else
        if (m_central.state != CBCentralManagerStatePoweredOn)
#endif
        {
            m_bNeedPowerOn = YES;
        }
        else
        {
            m_bNeedPowerOn = NO;
            [m_central stopScan];
            [m_central scanForPeripheralsWithServices:nil options:0]; // Start scanning
//            [m_central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
        }
    }
}
#else
-(void)startScan
{
    if (NO == m_central.isScanning) {
        if (@available(iOS 10.0, *))
        {
            if (m_central.state != CBManagerStatePoweredOn)
            {
                m_bNeedPowerOn = YES;
            }
            else
            {
                m_bNeedPowerOn = NO;
                [m_central stopScan];
                [m_central scanForPeripheralsWithServices:nil options:0]; // Start scanning
                    //            [m_central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
            }
        }
        else
        {
            if (m_central.state != CBCentralManagerStatePoweredOn)
            {
                m_bNeedPowerOn = YES;
            }
            else
            {
                m_bNeedPowerOn = NO;
                [m_central stopScan];
                [m_central scanForPeripheralsWithServices:nil options:0]; // Start scanning
                    //            [m_central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
            }
        }
    }
}
#endif

-(void)stopScan
{
    if (m_central.isScanning) {
        [m_central stopScan];
    }
}



-(void)setDelegate:(id)viewController
{
    m_delegate = viewController;
}

-(void)deleteDelegate
{
    m_delegate = nil;
}

#pragma mark - connect or disconnect



-(void)reconnectDevice
{
    m_bResponse = NO;
    if (m_central) {
        [m_central connectPeripheral:m_curPeripheral options:nil];
    }
}


-(void)connectDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData
{
    m_bResponse = NO;
    if (m_central && peripheral) {
        m_curAdDataDic = [[NSDictionary alloc] initWithDictionary:advertisementData];
        m_curPeripheral = peripheral;
        m_curPeripheral.delegate = self;
        peripheral.delegate = self;
        [m_central connectPeripheral:peripheral options:nil];
    }
}


- (void) connectDevice:(CBPeripheral *)peripheral 
{
    m_bResponse = NO;
    if (m_central && peripheral) {
        m_curPeripheral = peripheral;
        m_curPeripheral.delegate = self;
        peripheral.delegate = self;
        [m_central connectPeripheral:peripheral options:nil];
    }
}


-(void)disconnectDevice
{
    if (m_central && m_curPeripheral) {
        m_bDeleteDevice = YES;
//        [m_boundDeviceManager manuDisconnect:m_curPeripheral value:YES];
        [m_central cancelPeripheralConnection:m_curPeripheral];
//        m_curPeripheral = nil;
    }
}


-(void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    if(peripheral)
    {
        m_bDeleteDevice = YES;
        [m_central cancelPeripheralConnection:peripheral];
    }
}


-(void)discoverServices
{
    if (m_curPeripheral) {
        [m_curPeripheral discoverServices:nil];
    }
}

-(void)discoverServices:(CBPeripheral *)peri
{
    if (peri) {
        m_curPeripheral = peri;
        [m_curPeripheral discoverServices:nil];
    }
}
#pragma mark - bind or unbind

-(void)bindDevice
{
    //    if(m_msgType == msgBind || msgReconnect == m_msgType)
    {
        //        m_msgType = msgNone;
        
        [self startBind];
//        if (m_curPeripheral) {
//            [m_curPeripheral readRSSI];
//        }
    }
}



-(void)bindDevice:(CBPeripheral *)peripheral
{
    //    if (m_central && peripheral)
    
    if (m_central && peripheral)
    {
        m_curPeripheral = peripheral;
        
        [self sendBindCode:peripheral];
    }
    else if(m_central && m_curPeripheral)
    {
        [self sendBindDeviceII];
    }
}



-(void)unbindPharseIIDevice:(CBPeripheral *)peripheral
{
    if (peripheral) {
#if PARALLEL_BIND
        [m_boundDeviceManager setBindingStatus:peripheral status:statusUnbinding];
#else
        m_linkStatus = statusUnbinding;
#endif
        [self sendDataMessage:DEF_BLE_UNBIND_REQ]; // 二期解除绑定命令会有握手？？
//        [self sendDataMessage:DEF_BLE_UNBIND_REQ peripheral:peripheral];
    }
}


-(void)unbindDevice:(CBPeripheral *)peripheral
{
    if (peripheral) {
#if PARALLEL_BIND
        [m_boundDeviceManager setBindingStatus:peripheral status:statusUnbinding];
#else
        m_linkStatus = statusUnbinding;
#endif
        [self sendMessage:DEF_BLE_UNBIND_REQ peripheral:peripheral];
//        return;
        usleep(500 * 1000);
        
        [m_boundDeviceManager removePeripheral:peripheral];
        
        [self disconnectPeripheral:peripheral];
    }
    else if (m_central && m_curPeripheral) {
        [self cancelBind];
//        [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_BLE_STATUS object:nil];
    }
    else
    {// for test
        if (m_requireDelegate && [m_requireDelegate respondsToSelector:@selector(unbindDevice:)]) {
            [m_requireDelegate unbindDevice:m_curPeripheral];
        }
        
        if (m_boundDeviceManager) {
//            [m_boundDeviceManager removePeripheral:nil];
            BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
            [m_boundDeviceManager removeBound:theDev];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_BLE_STATUS object:nil];
        }
        
    }
}




-(void)cancelBind
{
    //    NSNotificationCenter *defaulCenter = [NSNotificationCenter defaultCenter];
    //    [defaulCenter postNotificationName:BIND_DEVICE_FAILED object:nil];
    [self sendDataMessage:DEF_BLE_UNBIND_REQ];
//    return;
    usleep(500 * 1000);
    
    if (m_requireDelegate && [m_requireDelegate respondsToSelector:@selector(unbindDevice:)]) {
        [m_requireDelegate unbindDevice:m_curPeripheral];
    }
    
    if (m_boundDeviceManager) {
        [m_boundDeviceManager removePeripheral:m_curPeripheral];
    }
    
    m_bDeleteDevice = YES;
#if PARALLEL_BIND
    [m_boundDeviceManager setBindingStatus:m_curPeripheral status:statusNone];
#else
    m_linkStatus = statusNone;
#endif
    [m_central cancelPeripheralConnection:m_curPeripheral];
}


-(void)startBind
{
#if PARALLEL_BIND
    m_linkStatus = [m_boundDeviceManager getBindingStatus:m_curPeripheral];
#endif
    if(m_linkStatus == statusBinded)
    {
        return;
    }
    DLog(@"");
    
#if PARALLEL_BIND
    [m_boundDeviceManager setBindingStatus:m_curPeripheral status:statusBinding];
#else
    m_linkStatus = statusBinding;
#endif
    if(m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)])
    {
        [m_delegate changeStatus:statusBinding];
    }
    DLog(@"STATUS = %ld", (long)m_linkStatus);
#if BLE_DEVICE_II
    [self sendBindDeviceII];
#else
    [self sendTheBinding];
#endif
    __weak BLEManager *weakSelf = self;
    dispatch_time_t delayTime1 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0/*延迟执行时间*/ * NSEC_PER_SEC));
    dispatch_after(delayTime1, dispatch_get_main_queue(), ^{
        typeof(self) theSelf = weakSelf;
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        NSString *connect = [user objectForKey:@"beginToReconnect"];
        if(NO == theSelf->m_bResponse && theSelf->m_linkStatus <= statusBinding && theSelf->m_linkStatus > statusNone)
        {
            DLog(@"绑定  超时1");
            //            [[tools shared] HUDShowHideText:@"重连失败" delay:2];
//            [weakSelf cancelBind];
            //            [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CONNECT_STATUS object:nil];
        }
        else if(theSelf->m_linkStatus <= statusBinding && theSelf->m_linkStatus > statusNone)
        {
            if(NO == [connect isEqualToString:@"重连成功"])
            {
                DLog(@"绑定  超时2");
            }
            else
            {
                DLog(@"绑定10秒后，检测绑定状态， 绑定成功");
            }
        }
    });
    
}



#pragma mark - send or receive

-(void)sendTheWakeup
{
    DLog(@"send the wakeup message ");
    [self sendDataMessage:@"FF"];
//    [self sendTheBinding];
    [self sendBindDeviceII];
}


-(void)sendWakeup:(CBPeripheral *)peripheral
{
    [self sendMessage:@"FF" peripheral:peripheral];
    [self sendBindCode:peripheral];
}



-(void)sendNewName:(NSString *)nameStr
{
    DLog(@"sendNewName");
    // : 58
    // - 45
    // TTM:REN-MyWeather0110
    
    NSString *hexString = nameStr;
    
#if 1
    NSData *newData = [hexString dataUsingEncoding:NSASCIIStringEncoding];
#else
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        if(i >= [hexString characterAtIndex:i])
        {
            break;
        }
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        //        NSLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:1];
#endif
    
    DLog(@" data %@，data = %@, Identifier = %@",[newData description],newData, [m_curPeripheral.identifier UUIDString]);
    [self writeValue:0xFFE5
  characteristicUUID:0xFFE9
                   p:m_curPeripheral
                data:newData];
}


-(void)sendDataMessage:(NSString *)messageS
{
    if (!m_curPeripheral) {
        DLog(@"----- m_curPeripheral为空 当前无绑定设备 ---------");
        return;
    }
    
    NSString *hexString = messageS;

    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        //        NSLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:1];
    
    DLog(@" data %@，data = %@, Identifier = %@",[newData description],newData, [m_curPeripheral.identifier UUIDString]);
    [self writeValue:0xFFE5
                    characteristicUUID:0xFFE9
                                     p:m_curPeripheral
                                  data:newData];
}


-(void)sendMessage:(NSString *)msgStr peripheral:(CBPeripheral *)peri
{
    NSString *hexString = msgStr;
    
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        //        NSLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:1];
    
    DLog(@"---- sendMessage: %@ -----", newData);
    [self writeValue:0xFFE5
  characteristicUUID:0xFFE9
                   p:peri
                data:newData];
}


-(void)sendDataMessage:(NSData *)msgData peripheral:(CBPeripheral *)peri
{
    DLog(@"---- msgData: %@ -----", msgData);
    [self writeValue:0xFFE5
  characteristicUUID:0xFFE9
                   p:peri
                data:msgData];
}



-(void)changeStaus:(statusLink)status success:(BOOL)result
{
//    if (m_delegate && [m_delegate respondsToSelector:@selector(changeDeviceStatus:result:)]) {
//        [m_delegate changeDeviceStatus:status result:result];
//    }

    if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
        [m_delegate changeStatus:statusBinded];
    }
}


-(void)changeConnectStatus:(connectStatus)status peripheral:(CBPeripheral *)peri
{
    if ([peri.identifier.UUIDString isEqualToString:m_curPeripheral.identifier.UUIDString]) {
        [m_boundDeviceManager changeDevStatus:status peripheral:m_curPeripheral];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_BLE_STATUS object:nil];
    }
}


-(void)sendBindCode:(CBPeripheral *)peripheral
{
    NSString* identifierNumber = [[UIDevice currentDevice].identifierForVendor UUIDString] ;
    //    NSLog(@"手机序列号: %@",identifierNumber);
    
    NSString *strUrl = [identifierNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    strUrl = [NSString stringWithFormat:@"%@%@%@", DEF_BLE_CHECK_CODE_STA, strUrl, DEF_BLE_CHECK_CODE_END];
    DLog(@"%@", strUrl);
#if 1
    NSString *hexString = strUrl;
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:18];
#else
    
    NSData *newData = [strUrl dataUsingEncoding:NSASCIIStringEncoding];
#endif
    
    DLog(@"bind data %@，data = %@, Identifier = %@",[newData description],newData, [m_curPeripheral.identifier UUIDString]);
    
    [self writeValue:0xFFE5
  characteristicUUID:0xFFE9
                   p:peripheral
                data:newData];
}


-(void)sendBindDeviceII
{
    NSString* identifierNumber = [[UIDevice currentDevice].identifierForVendor UUIDString] ;
//    NSLog(@"手机序列号: %@",identifierNumber);
    
    NSString *strUrl = [identifierNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    strUrl = [NSString stringWithFormat:@"%@%@%@", DEF_BLE_CHECK_CODE_STA, strUrl, DEF_BLE_CHECK_CODE_END];
    DLog(@"%@", strUrl);
#if 1
    NSString *hexString = strUrl;
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:18];
#else
    
    NSData *newData = [strUrl dataUsingEncoding:NSASCIIStringEncoding];
#endif
    
    DLog(@"bind data %@，data = %@, Identifier = %@",[newData description],newData, [m_curPeripheral.identifier UUIDString]);
    
    [self writeValue:0xFFE5
  characteristicUUID:0xFFE9
                   p:m_curPeripheral
                data:newData];
}


- (void)sendTheBinding
{
    NSString* identifierNumber = [[UIDevice currentDevice].identifierForVendor UUIDString] ;
    DLog(@"手机绑定码: %@",identifierNumber);
    
    NSString *strUrl = [identifierNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];

    strUrl = [NSString stringWithFormat:@"%@%@%@", @"F1", strUrl, @"1F"];

    NSString *hexString = strUrl;
    
    int j=0;
    Byte bytes[128];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:18];
    
    
    DLog(@"bind data %@，data = %@, Identifier = %@",[newData description],newData, [m_curPeripheral.identifier UUIDString]);
    
    [self writeValue:0xFFE5
                    characteristicUUID:0xFFE9
                                     p:m_curPeripheral
                                  data:newData];
}


/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/*!
 *  @method writeValue:
 *
 *  @param serviceUUID Service UUID to write to (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to write to (e.g. 0x2401)
 *  @param data Data to write to peripheral
 *  @param p CBPeripheral to write to
 *
 *  @discussion Main routine for writeValue request, writes without feedback. It converts integer into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, value is written. If not nothing is done.
 *
 */

-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    if (m_curPeripheral == nil) {
//        [[tools shared] HUDShowHideText:@"连接已经断开" delay:2];
    }
    
    usleep(10*1000);
    
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];

    CBService *service = [self findServiceFromUUID:su p:p];

    if (!service) {

        DLog(@"NO SERVICE!!");
        [m_boundDeviceManager writeDataNeedWait:p message:data];
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        
        [m_boundDeviceManager writeDataNeedWait:p message:data];
        return;
    }
    
#if 1
//    m_bWriteNoReponse = [m_boundDeviceManager getDevVersion:p] == 2 ? YES : NO;
    m_bWriteNoReponse = YES;//[m_boundDeviceManager getWriteResponse:p];
//    if (m_linkStatus <= statusBinding && m_bWriteNoReponse) {//一期和二期对写数据有有无响应的区分。不然会报错，无法写成功
    if(m_bWriteNoReponse){
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse]; // response
        return;
    }
#endif
//    m_bWriteNoReponse = NO;
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse]; // response
}


-(void) writeValueNoResponse:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    if (m_curPeripheral == nil) {
        //        [[tools shared] HUDShowHideText:@"连接已经断开" delay:2];
    }
    
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];

    CBService *service = [self findServiceFromUUID:su p:p];

    if (!service) {
        
        DLog(@"NO SERVICE!!");
        [m_boundDeviceManager writeDataNeedWait:p message:data];
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        
        [m_boundDeviceManager writeDataNeedWait:p message:data];
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
 *  to find a characteristic with a specific UUID
 *
 */
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}


/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
 *  service with a specific UUID
 *
 */
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    NSInteger nDataLen = 16;
    char b1[nDataLen];
    char b2[nDataLen];
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_8_0
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
#else
    [UUID1.data getBytes:b1 length:nDataLen];
    [UUID2.data getBytes:b2 length:nDataLen];
#endif
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

-(recDataType)isHistoryData:(NSString *)dataStr
{
    NSMutableString *muttemStr = [NSMutableString stringWithString:dataStr];
    if ([muttemStr length] < 10) {
        return dataOther;
    }
    NSString *frstChar = [muttemStr substringWithRange:NSMakeRange(0, 1)];

    if ([frstChar isEqualToString:@"Q"]) {
        return dataHis;
    }
    
    if ([frstChar isEqualToString:@"+"] || [frstChar isEqualToString:@"-"]) {
        return dataData;
    }
    
    return dataOther;
}



// response code is "F7"
-(void)processResponseCode:(CBPeripheral *)peripheral
{
#if PARALLEL_BIND
    m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
    switch (m_linkStatus) {
        case statusUnbinding:
        {
            [m_boundDeviceManager disconnectPeri:peripheral];
            [self disconnectPeripheral:peripheral];
        }
            break;
        default:
            break;
    }
}


- (void)recvDeviceData:(CBCharacteristic *)tempcharacter peripheral:(CBPeripheral *)peripheral
{
    NSMutableString *receiveStr = [NSMutableString string];
    
    //这里取出刚刚从过来的字符串
    CBCharacteristic *tmpCharacter = tempcharacter;
    CHAR_STRUCT buf1;
    //将获取的值传递到buf1中；
    [tmpCharacter.value getBytes:&buf1 length:tmpCharacter.value.length];
    
    DLog(@"recv-接收到的数据为%@，字符串%@, m_linkStatus = %d",tmpCharacter.value,receiveStr, (int)m_linkStatus);
    
    for(int i =0;i<tmpCharacter.value.length;i++)
    {
        [receiveStr appendString:[CommonFunc stringFromHexString:[NSString stringWithFormat:@"%02X",buf1.buff[i]&0x000000ff]]];
    }
    
#if PARALLEL_BIND
    m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
    if (/*m_linkStatus == statusGetVer && */[receiveStr isEqualToString:@"02"]) {
//        m_nDeviceVer = [receiveStr integerValue];
        [m_boundDeviceManager setDevVersion:2 peripheral:peripheral];
        return;
    }
    
    m_bResponse = YES;
    
    if (receiveStr.length >= 9)
    {
        recDataType dataType = [self isHistoryData:receiveStr];
        if (m_bGetHistory && dataHis == dataType) {
            DLog(@"hisData: %@\n", receiveStr);
            return;
        }
        
        if (dataType == dataData) {
            DLog(@"update data %@", receiveStr);
            [self updateData:receiveStr peripheral:peripheral];
            return;
        }
        DLog(@"update data");
    }else {
        m_bGetHistory = NO;
        Byte *bytes = (Byte *)[tmpCharacter.value bytes];
        NSString *hexStr=@"";
        for(int i=0;i<[tmpCharacter.value length];i++)
        {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff]; ///16进制数
            if([newHexStr length]==1)
                hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
            else
                hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
        DLog(@"bytes 的16进制数为:%@",hexStr);
        
        if (m_delegate && [m_delegate respondsToSelector:@selector(showRecivedData:)]) {
            [m_delegate showRecivedData:hexStr];
        }
        // 原则上只有设备唤醒时，才会收到ff
        if (([hexStr rangeOfString:@"ff"].location != NSNotFound || [hexStr rangeOfString:@"FF"].location != NSNotFound || [hexStr rangeOfString:@"F2"].location != NSNotFound || [hexStr rangeOfString:@"f2"].location != NSNotFound)) {
#if PARALLEL_BIND
            [m_boundDeviceManager setBindingStatus:peripheral status:statusWakingup];
#else
            m_linkStatus = statusWakeup;
#endif
            DLog(@"STATUS = %ld", (long)m_linkStatus);
            
            if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
                [m_delegate changeStatus:statusWakeup];
            }
            
            [self startBind];
            return;
        }
        
//        if (([hexStr rangeOfString:@"F2"].location != NSNotFound || [hexStr rangeOfString:@"f2"].location != NSNotFound) ) // && statusBinding > m_linkStatus // for Phase1
        if (([hexStr rangeOfString:@"F2"].location != NSNotFound || [hexStr rangeOfString:@"f2"].location != NSNotFound) && statusBinding > m_linkStatus)
        { // 用于检测绑定码，发送后，接收不匹配重发绑定码
            DLog(@"resend the bind code !!");
#if PARALLEL_BIND
            [m_boundDeviceManager setBindingStatus:peripheral status:statusWakeup];
#else
                m_linkStatus = statusWakeup;
#endif
                [self changeStaus:statusWakeup success:YES];
#if PARALLEL_BIND
            [m_boundDeviceManager setBindingStatus:peripheral status:statusBinding];
#else
            m_linkStatus = statusBinding;
#endif
                if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
                    [m_delegate changeStatus:statusBinding];
                }
            if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
                [m_delegate changeStatus:statusBinding];
            }
                DLog(@"STATUS = %ld", (long)m_linkStatus);
                [self startBind];

            return;
        }
        
        
        if ([hexStr rangeOfString:@"aa"].location != NSNotFound || [hexStr rangeOfString:@"AA"].location != NSNotFound) {
            DLog(@"发弹窗了");
            //设备正在寻找app
            //            [self changeStaus:stat success:yes];
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            
            
            NSString *clickTime = [user objectForKey:@"ClickWaringTime"];
            
            
//            NSDate *senddate = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            
            [dateformatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            
            // 截止时间字符串格式
            NSString *expireDateStr = clickTime;
            DLog(@"%@", expireDateStr);
            // 当前时间字符串格式
//            NSString *nowDateStr = [dateformatter stringFromDate:senddate];
            {
                
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                
                [center postNotificationName:@"DeviceSendAWarning" object:nil];
                
//                [user setObject:nowDateStr forKey:@"ClickWaringTime"];
//                [user synchronize];
                
            }
            
            
        }else if ([hexStr rangeOfString:DEF_DEV_BIND_SUC].location != NSNotFound || [hexStr rangeOfString:@"EF"].location != NSNotFound) {
            [self bindSuccessed:peripheral];
        }else if ([hexStr rangeOfString:@"ee"].location != NSNotFound || [hexStr rangeOfString:@"EE"].location != NSNotFound)
        {
#if 1
            if(m_delegate && [m_delegate respondsToSelector:@selector(showAlert:msg:)])
            {
                [m_delegate showAlert:@"提示" msg:@"设备电量过低，请注意"];
            }
#else
            [self deviceLowPowerNotification]; // 电量只会主动获取数据时，附加收到电量低的数据。 所以不会在后台时收到电量低的数据
#endif
        }else if ([hexStr rangeOfString:@"cd"].location != NSNotFound || [hexStr rangeOfString:DEF_DEV_BIND_FAILED].location != NSNotFound) {
            [self deviceReciveBindDataFaild];
            return;

        }
        else if([hexStr rangeOfString:DEF_DEV_NO_AUTH].location != NSNotFound)
        {
            [self bindFailed:peripheral];
        }
        else if([hexStr rangeOfString:DEF_DEV_RESPONSE].location != NSNotFound)
        {
#if PARALLEL_BIND
            m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
            if(m_linkStatus > statusGetVer)
            {
                [self processResponseCode:peripheral];
            }
        }
        else if([hexStr isEqualToString:@"bb"] || [hexStr isEqualToString:@"BB"])
        {
            [self beBound:peripheral];
        }
        else if([hexStr isEqualToString:@"F7"] || [hexStr isEqualToString:@"f7"])
        {
#if PARALLEL_BIND
            m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
            if (m_linkStatus < statusBinding) {
                [self sendBindDeviceII];
#if PARALLEL_BIND
                [m_boundDeviceManager setBindingStatus:peripheral status:statusBinding];
#else
                m_linkStatus = statusBinding;
#endif
            }
            else if(m_linkStatus == statusBinding)
            {
#if PARALLEL_BIND
                [m_boundDeviceManager setBindingStatus:peripheral status:statusBinded];
#else
                m_linkStatus = statusBinded;
#endif
                [self reconnectSuccessed:peripheral];
            }
        }
        else if([hexStr isEqualToString:DEF_DEV_MODIFY_NAME_SUC] || [hexStr isEqualToString:@"F9"])
        {
            [m_boundDeviceManager setBindName:nil deviceName:m_devNewName peripheral:peripheral];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_BLE_STATUS object:nil];
        }
        else if([hexStr isEqualToString:DEF_DEV_MODIFY_NAME_FAILD])
        {
//            DLog(@"");
        }
        else if([hexStr isEqualToString:DEF_DEV_SET_RING3_SUC] || [hexStr isEqualToString:DEF_DEV_SET_RING2_SUC] || [hexStr isEqualToString:DEF_DEV_SET_RING1_SUC])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_SET_RING_SUC object:hexStr];
        }
    }
    
}


-(void)deviceReciveBindDataFaild
{
    if(statusWakingup == m_linkStatus)
    {
#if PARALLEL_BIND
//        [m_boundDeviceManager setBindingStatus:peripheral  status:statusWakeup];
#else
        m_linkStatus = statusWakeup;
#endif
    }
//    else
    {
        [self changeStaus:statusWakeup success:YES];
        m_linkStatus = statusBinding;
        DLog(@"STATUS = %ld", (long)m_linkStatus);
        [self startBind];
    }
    if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
        [m_delegate changeStatus:m_linkStatus];
    }

}

-(void)reconnectSuccessed:(CBPeripheral *)peripheral
{
#if PARALLEL_BIND
    [m_boundDeviceManager setBindingStatus:peripheral status:statusBinded];
#else
    m_linkStatus = statusBinded;
#endif
    
    DLog(@"STATUS = %ld", (long)m_linkStatus);
    [self changeStaus:statusBinded success:YES];
    //    [self saveDefaultBindUUID:peripheral];
    
    if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
        [m_delegate changeStatus:statusBinded];
    }
    
    [m_boundDeviceManager addPeripheral:peripheral];
    [self getDeviceVer:peripheral];
    
    [self changeConnectStatus:ble_connected peripheral:peripheral];
}

-(void)bindSuccessed:(CBPeripheral *)peripheral
{
#if PARALLEL_BIND
    [m_boundDeviceManager setBindingStatus:peripheral status:statusBinded];
#else
    m_linkStatus = statusBinded;
#endif
    DLog(@"STATUS = %ld", (long)m_linkStatus);
    [self changeStaus:statusBinded success:YES];
//    [self saveDefaultBindUUID:peripheral];
    
    if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
        [m_delegate changeStatus:statusBinded];
    }
    
    [m_boundDeviceManager addPeripheral:peripheral];
    [m_boundDeviceManager setBindName:nil deviceName:peripheral.name peripheral:peripheral];
    [self getDeviceVer:peripheral];

    [self changeConnectStatus:ble_connected peripheral:peripheral];

//    [self sendDataMessage:@"01"];
    [self performSelector:@selector(getDevData) withObject:nil afterDelay:1];
}


-(void)getDevData
{
    [self sendDataMessage:@"01"];
}


-(void)bindFailed:(CBPeripheral *)peri
{
    m_bDeleteDevice = YES;
    [m_central cancelPeripheralConnection:peri];
    
    m_linkStatus = statusNone;
    DLog(@"STATUS = %ld", (long)m_linkStatus);

    if(m_delegate && [m_delegate respondsToSelector:@selector(showAlert:msg:)])
    {
        [m_delegate showAlert:@"提示" msg:@"该设备已被绑定"];
    }
}


-(void)beBound:(CBPeripheral *)peri
{
    m_bDeleteDevice = YES;
    [m_central cancelPeripheralConnection:peri];
    
    m_linkStatus = statusNone;
    DLog(@"STATUS = %ld", (long)m_linkStatus);
    
    if(m_delegate && [m_delegate respondsToSelector:@selector(showAlert:msg:)])
    {
        [m_delegate showAlert:@"提示" msg:@"该设备已被绑定"];
    }
    
}


-(void)getDeviceVer:(CBPeripheral *)peripheral
{
//    m_linkStatus = statusGetVer;
    [m_boundDeviceManager setBindingStatus:peripheral status:statusGetVer];
//    [self sendDataMessage:DEF_BLE_VERSION_REQ];
    [self sendMessage:DEF_BLE_VERSION_REQ peripheral:peripheral];
}


-(void)updateData:(NSString *)dataStr peripheral:(CBPeripheral *)peripheral
{
    if (!dataStr || !peripheral) {
        return;
    }
    
    NSMutableString *recivedStr = [NSMutableString stringWithFormat:@"%@", dataStr];
    if (recivedStr.length == 9) {
        [recivedStr appendFormat:@"0"];
    }
    
    NSMutableString *muttemStr = [NSMutableString stringWithString:dataStr];
    
    //温度
    NSString *temLabelStr = [muttemStr substringWithRange:NSMakeRange(0, 3)];
    //如果是正数去掉+号
    NSString *temLabel = [temLabelStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
    NSString *humLabelStr = [muttemStr substringWithRange:NSMakeRange(3, 2)];
    NSString *preLabelStr = [muttemStr substringWithRange:NSMakeRange(5, 3)];
    NSString *eleLabelStr = [muttemStr substringWithRange:NSMakeRange(8, 2)];
    MEBLEModel *model = [[MEBLEModel alloc] init];
    
    model.temperature = temLabel;
    model.humidity = humLabelStr;
    model.pressure = preLabelStr;
    model.electricity = eleLabelStr;
    model.PM = @"25";
    
    
    [[GlobalData shareData] setModelData:model];
    
    if (m_delegate && [m_delegate respondsToSelector:@selector(updateData:)]) {
        [m_delegate updateData:model];
    }
    
//    [[DataUpload shareInstance] dataUploadReq:model]; // 暂时取消上传数据
}



- (void)addChange:(CBCharacteristic *)tempcharacter peripheral:(CBPeripheral *)peripheral
{
    NSMutableString *receiveStr = [NSMutableString string];
    
    //这里取出刚刚从过来的字符串
    CBCharacteristic *tmpCharacter = tempcharacter;
    CHAR_STRUCT buf1;
    //将获取的值传递到buf1中；
    [tmpCharacter.value getBytes:&buf1 length:tmpCharacter.value.length];
    
    if ([@"2A29" isEqualToString: tmpCharacter.UUID.UUIDString]) {
        return;
    }
    DLog(@"接收到的数据为%@，字符串%@, m_linkStatus = %d",tmpCharacter.value,receiveStr, (int)m_linkStatus);

    for(int i =0;i<tmpCharacter.value.length;i++)
    {
        [receiveStr appendString:[CommonFunc stringFromHexString:[NSString stringWithFormat:@"%02X",buf1.buff[i]&0x000000ff]]];
    }
    
    m_bResponse = YES;
#if PARALLEL_BIND
    m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
//    if (m_linkStatus == statusGetVer && ([receiveStr isEqualToString:@"\x02"] || [receiveStr isEqualToString:@"02"]))
    if ([receiveStr isEqualToString:@"02"])
    {
        [m_boundDeviceManager setDevVersion:2 peripheral:peripheral];
        return;
    }
    
    if (receiveStr.length >= 9 && NO == [receiveStr hasPrefix:@"v_"]){
        
        if (m_bGetHistory) {
            [[HistoryData shareInstance] addData:receiveStr];
            
            NSInteger nCount = [[HistoryData shareInstance] dataCount];
            if (nCount >= 24) {
                m_bGetHistory = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_HISTORY_DATA_READY object:nil];
            }
            return;
        }
        [self updateData:receiveStr peripheral:peripheral];
                DLog(@"update data");
    }else {
        
        Byte *bytes = (Byte *)[tmpCharacter.value bytes];
        NSString *hexStr=@"";
        for(int i=0;i<[tmpCharacter.value length];i++)
        {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff]; ///16进制数
            if([newHexStr length]==1)
                hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
            else
                hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
        DLog(@"bytes 的16进制数为:%@",hexStr);
        
        // 原则上只有设备唤醒时，才会收到ff
        if (([hexStr rangeOfString:@"ff"].location != NSNotFound || [hexStr rangeOfString:@"FF"].location != NSNotFound || [hexStr rangeOfString:@"F2"].location != NSNotFound || [hexStr rangeOfString:@"f2"].location != NSNotFound) && m_linkStatus < statusBinded) {
#if PARALLEL_BIND
            [m_boundDeviceManager setBindingStatus:peripheral status:statusWakeup];
#else
            m_linkStatus = statusWakeup;
#endif
            if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
                [m_delegate changeStatus:statusWakeup];
            }
            [self bindDevice:peripheral];
            
            return;
        }
        
        if (([hexStr rangeOfString:@"F2"].location != NSNotFound || [hexStr rangeOfString:@"f2"].location != NSNotFound)) { // 用于检测绑定码，发送后，接收不匹配重发绑定码
            DLog(@"resend the bind code !!");
#if PARALLEL_BIND
            m_linkStatus = [m_boundDeviceManager getBindingStatus:peripheral];
#endif
            if(statusWakingup == m_linkStatus)
            {
#if PARALLEL_BIND
                [m_boundDeviceManager setBindingStatus:peripheral status:statusWakeup];
#else
                m_linkStatus = statusWakeup;
#endif
            }
            else
            {
                [self changeStaus:statusWakeup success:YES];
#if PARALLEL_BIND
                [m_boundDeviceManager setBindingStatus:peripheral status:statusBinding];
#else
                m_linkStatus = statusBinding;
#endif
                [self startBind];
            }
            if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
                [m_delegate changeStatus:statusBinding];
            }
            return;
        }
        
        
        if ([hexStr rangeOfString:@"aa"].location != NSNotFound || [hexStr rangeOfString:@"AA"].location != NSNotFound) { // 待整理
            DLog(@"发弹窗了");
            //设备正在寻找app
//            [self changeStaus:stat success:yes];
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            NSString *clickTime = [user objectForKey:@"ClickWaringTime"];
            
            NSDate *senddate = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            
            [dateformatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            
            // 截止时间字符串格式
            NSString *expireDateStr = clickTime;
            DLog(@"%@", expireDateStr);
            // 当前时间字符串格式
            NSString *nowDateStr = [dateformatter stringFromDate:senddate];
            {
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:@"DeviceSendAWarning" object:nil];

                //将值设为yes
                [user setObject:nowDateStr forKey:@"ClickWaringTime"];
                [user synchronize];
            }
        }else if ([hexStr rangeOfString:@"ef"].location != NSNotFound || [hexStr rangeOfString:@"EF"].location != NSNotFound) {
            [self bindSuccessed:peripheral];

        }else if ([hexStr rangeOfString:@"ee"].location != NSNotFound || [hexStr rangeOfString:@"EE"].location != NSNotFound)
        {
#if 1
            if(m_delegate && [m_delegate respondsToSelector:@selector(showAlert:msg:)])
            {
                [m_delegate showAlert:@"提示" msg:@"设备电量过低，请注意"];
            }
#else
            [self deviceLowPowerNotification]; // 电量只会主动获取数据时，附加收到电量低的数据。 所以不会在后台时收到电量低的数据
#endif
        }else if (([hexStr rangeOfString:@"cd"].location != NSNotFound || [hexStr rangeOfString:@"CD"].location != NSNotFound)) {
            if (m_linkStatus < statusBinding) {
                // 在状态小于绑定中时，收到设备cd码，为绑定失败。重新发送绑定码
                [self bindDevice:peripheral];
            }
            else
            {
                // 在绑定中，收到cd码，表示一期设备已经被绑定
                [self bindFailed:peripheral];
            }
        }
        else if([hexStr isEqualToString:@"bb"] || [hexStr isEqualToString:@"BB"])
        {
            [self beBound:peripheral];
        }
        else if([hexStr isEqualToString:@"F7"] || [hexStr isEqualToString:@"f7"])
        {
            [m_boundDeviceManager setDevVersion:2 peripheral:peripheral]; // 能收到F7 码，表示是二期设备
            if (m_linkStatus < statusBinding) {
#if PARALLEL_BIND
#else
                m_linkStatus = statusBinding;
#endif
                [self sendBindDeviceII];
            }
            
            if (statusBinded == m_linkStatus) {
#if PARALLEL_BIND
                [m_boundDeviceManager setBindingStatus:peripheral status:statusBinded];
#else
                m_linkStatus = statusBinded;
#endif
                [self bindSuccessed:peripheral];
            }
        }
        else if([hexStr isEqualToString:DEF_DEV_MODIFY_NAME_SUC] || [hexStr isEqualToString:@"F9"])
        {
            [m_boundDeviceManager setBindName:nil deviceName:m_devNewName peripheral:peripheral];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_BLE_STATUS object:nil];
        }
        else if([hexStr isEqualToString:@"ab"] || [hexStr isEqualToString:@"AB"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_DEV_CANCEL_CALL object:nil];
        }
    }
    
}



/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using NSLog()
 *
 */
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}



- (void) notificationWithUUID:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    if (!service) {
       DLog(@"Could not find service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        DLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        //        NSLog(@"Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:p.UUID]);
        DLog(@"service == nil");
        if(statusBinded == m_linkStatus)
        {
            [self connectDevice:m_curPeripheral];
        }
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        //        NSLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:p.UUID]);
        DLog(@"characteristic == nil");
        if(statusBinded == m_linkStatus)
        {
            [self connectDevice:m_curPeripheral];
        }
        return;
    }
    DLog(@"characteristic = %@", characteristic);
    [p setNotifyValue:on forCharacteristic:characteristic];
}


/*
 *  @method getAllCharacteristicsFromKeyfob
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllCharacteristicsFromKeyfob starts a characteristics discovery on a peripheral
 *  pointed to by p
 *
 */

//获取所有服务的特征值
-(void) getAllCharacteristicsFromKeyfob:(CBPeripheral *)p{
    //读取所有服务的特征值
    for (int i=0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        //开始读取当前服务的特征值
        [p discoverCharacteristics:nil forService:s];
    }
}

#pragma mark - User interface
-(void)getHistoryData
{
    m_bGetHistory = YES;
    [[HistoryData shareInstance] cleanData];
    [self sendDataMessage:@"FD"];
}


-(void)cancelGetHistoryData
{
    m_bGetHistory = NO;
    [[HistoryData shareInstance] cleanData];
}


-(void)setBindDisturb:(BOOL)bDisturb
{
    m_bSendGuard = YES;
    if (bDisturb) {
//        [UserDefault setStringVaule:@"1" key:USER_DISTURB_ON];
        [self sendDataMessage:DEF_BLE_OPEN_DISTURB_REQ];
    }
    else
    {
//        [UserDefault setStringVaule:@"0" key:USER_DISTURB_ON];
        [self sendDataMessage:DEF_BLE_CLOSE_DISTUREB_REQ];
    }
}

-(void)modifyBindName:(NSString *)bindName
{
    [m_boundDeviceManager setBindName:bindName deviceName:nil peripheral:m_curPeripheral];
}

-(void)modifyDevName:(NSString *)devName
{
    [self sendDataMessage:DEF_BLE_MODIFY_NAME_REQ];
    
    m_devNewName = [NSString stringWithFormat:@"%@", devName];
//    NSString *utf8Str = [NSString stringWithCString:[devName UTF8String] encoding:NSUTF8StringEncoding];
    NSData *data = [devName dataUsingEncoding:NSUTF8StringEncoding];
    [self sendDataMessage:data peripheral:m_curPeripheral];
}


-(NSString *)getCurPeriName
{
//    return m_curPeripheral.name;
    BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
//    if (theDev.m_setNameStr && [theDev.m_setNameStr length] > 0) {
//        return theDev.m_setNameStr;
//    }
    
    return theDev.m_deviceNameStr;
}


-(NSString *)getCurBindName
{
    BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
    if (theDev.m_setNameStr && [theDev.m_setNameStr length] > 0) {
        return theDev.m_setNameStr;
    }
    
    return theDev.m_deviceNameStr;
}


-(void)setCurPeriName:(NSString *)periName
{
    
}

-(void)setCurBindName:(NSString *)bindName
{
    BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
    if (theDev && bindName && [bindName length]) {
        theDev.m_setNameStr = [NSString stringWithFormat:@"%@", bindName];
    }
}



-(connectStatus)getFocusDevStatus
{
    if (m_boundDeviceManager) {
        return [m_boundDeviceManager getFocusDevStatus];
    }
    
    return ble_unbind;
}


-(CBPeripheral *)getFocusDevice
{
    BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
    DeviceStatusInfo *theInfo = [m_boundDeviceManager getDeviceInfo:theDev.m_UUIDstr];
    
    if (theInfo) {
        return theInfo.m_peri;
    }
    
    return nil;
}

-(NSDictionary *)getDeviceData:(NSInteger)nRow
{
    BoundDevice *theDev = [m_boundDeviceManager getBoundDevice:nRow];
    DeviceStatusInfo *theInfo = [m_boundDeviceManager getDeviceInfo:theDev.m_UUIDstr];
    NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
    if (theDev) {
        [retDic setObject:theDev forKey:@"BOUND_DEVICE"];
    }
    if (theInfo) {
        [retDic setObject:theInfo forKey:@"DEVICE_INFO"];
    }
    return retDic;
}


-(NSInteger)getFocusDeviceIndex
{
    NSInteger nIndex = [m_boundDeviceManager getFocusdDeviceIndex];
    return nIndex;
}


-(void)setBindName:(NSString *)bindName; //用户指定的被绑定物品名称
{
    if (bindName && [bindName length] > 0) {
        NSString *devName = @"";
        if (m_curAdDataDic) {
            NSString *name = GET([m_curAdDataDic objectForKey:@"kCBAdvDataLocalName"]);
            devName = [NSString stringWithFormat:@"%@", name];
        }
        
        [m_boundDeviceManager setBindName:bindName deviceName:devName peripheral:m_curPeripheral];
    }
    else
    {
        NSString *devName = @"";
        if (m_curAdDataDic) {
            NSString *name = GET([m_curAdDataDic objectForKey:@"kCBAdvDataLocalName"]);
            devName = [NSString stringWithFormat:@"%@", name];
        }
        
        [m_boundDeviceManager setBindName:devName deviceName:devName peripheral:m_curPeripheral];
    }
}


-(void)setFocusPeri:(CBPeripheral *)peri
{
    m_curPeripheral = peri;
    [m_boundDeviceManager changeFocus:peri];
}


-(void)sendGuardMessage:(CBPeripheral *)peri
{
    [self sendMessage:DEF_BLE_OPEN_MANAGER_REQ peripheral:peri];
}


#pragma mark - user default
-(void)saveDefaultBindUUID:(CBPeripheral *)per
{
    if (!m_boundUUIDArr) {
        m_boundUUIDArr = [[NSMutableArray alloc] init];
    }
    
    NSInteger nIndex = [m_boundUUIDArr indexOfObject:[per.identifier UUIDString]];
    if(nIndex == NSNotFound)
    {
        [m_boundUUIDArr addObject:[per.identifier UUIDString]];
    }
    
    NSString *userStr = @"";
    for(NSInteger i = 0; i < [m_boundUUIDArr count]; i++)
    {
        NSString *subStr = [m_boundUUIDArr objectAtIndex:i];
        if (i == 0) {
            userStr = [NSString stringWithFormat:@"%@", userStr];
        }
        else
        {
            userStr = [NSString stringWithFormat:@"%@,%@", userStr, subStr];
        }
    }
    [UserDefault setStringVaule:userStr key:USER_BIND_DEVICE];
    
    NSInteger nNum = [m_boundUUIDArr count];
    [UserDefault setBindDeviceNum:nNum];
}


-(void)deleteDefaultBindUUID:(CBPeripheral *)per
{
    if (!m_boundUUIDArr) {
        m_boundUUIDArr = [[NSMutableArray alloc] init];
    }
    
    [m_boundUUIDArr removeObject:[per.identifier UUIDString]];
    
    NSString *userStr = @"";
    for(NSInteger i = 0; i < [m_boundUUIDArr count]; i++)
    {
        NSString *subStr = [m_boundUUIDArr objectAtIndex:i];
        if (i == 0) {
            userStr = [NSString stringWithFormat:@"%@", userStr];
        }
        else
        {
            userStr = [NSString stringWithFormat:@"%@,%@", userStr, subStr];
        }
    }
    [UserDefault setStringVaule:userStr key:USER_BIND_DEVICE];
    
    NSInteger nNum = [m_boundUUIDArr count];
    [UserDefault setBindDeviceNum:nNum];
}


#pragma mark - central delegate


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    DLog(@"");
    switch (central.state) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3
        case CBManagerStatePoweredOff:
#else
        case CBCentralManagerStatePoweredOff:
#endif
            m_bNeedPowerOn = YES;
            DLog(@"bluetooth power off");
//            [self connectDevice:m_curPeripheral];
            [self changeConnectStatus:ble_disconnect peripheral:m_curPeripheral];
            if (m_curPeripheral) {
//                [m_central cancelPeripheralConnection:m_curPeripheral];
            }
            break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3
        case CBManagerStatePoweredOn:
#else
        case CBCentralManagerStatePoweredOn:
#endif
            if (m_curPeripheral) {
                m_bNeedPowerOn = NO;
//                [self connectAllDevice]; // Demo 不需要重连
                break;
            }
            DLog(@"bluetooth power on");
            if (m_bNeedPowerOn) {
                m_bNeedPowerOn = NO;
                [self startScan];
            }
            break;
        default:
            break;
    }
}

-(void)connectAllDevice
{
    NSInteger nCount = [UserDefault getBindNum];
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDeviceManager getBoundDevice:i];
        if (theDev && theDev.m_UUIDstr) {
            DeviceStatusInfo *theDic = [m_boundDeviceManager getDeviceInfo:theDev.m_UUIDstr];
            if (theDic.m_peri) {
                [self connectDevice:theDic.m_peri];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    DLog(@"%@\n", peripheral);
    DLog(@"\n--- peripheral name = %@, advertisement name = %@\n", peripheral.name, [advertisementData objectForKey:@"kCBAdvDataLocalName"]);
    if(m_delegate && [m_delegate respondsToSelector:@selector(discoverDevice:advertisementData:RSSI:)])
    {
        [m_delegate discoverDevice:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
    else
    {
        [m_boundDeviceManager discoverDevice:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (m_delegate && [m_delegate respondsToSelector:@selector(didConnectDevice:)])
    {
        [m_delegate didConnectDevice:peripheral];
    }
//    if (m_bUpgrade) {
//        [peripheral discoverServices:nil];
//        return;
//    }
//
//#if PARALLEL_BIND
//    [m_boundDeviceManager setBindingStatus:peripheral status:statusConnected];
//#else
//    m_linkStatus = statusConnected;
//#endif
//    m_bWriteNoReponse = NO;
//
//    [self changeConnectStatus:ble_disconnect peripheral:peripheral];
//
//    if (m_delegate && [m_delegate respondsToSelector:@selector(didConnectDevice:)]) {
//
//        m_curPeripheral = peripheral;// 用于第一次连接上，但是未绑定成功的设备，断开连接
//        m_curPeripheral.delegate = self;
//
//        [m_boundDeviceManager connectedPeri:peripheral];
//        [m_delegate didConnectDevice:peripheral];
//
//        [peripheral discoverServices:nil];
//    }
//    else if(m_boundDeviceManager)
//    {
//        [m_boundDeviceManager connectedPeri:peripheral];
//
//        [peripheral discoverServices:nil];
//    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    DLog(@"");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    if (m_delegate && [m_delegate respondsToSelector:@selector(changeStatus:)]) {
        [m_delegate changeStatus:statusDisconnected];
    }
    return;
//    if (m_bUpgrade) {
//        m_curPeripheral = nil;
//        [[BLEManager ShareInstance] unbindDevice:peripheral];
//        m_bUpgrade = NO;
//        return;
//    }
//    DLog(@"error:%@", error);
//    [m_boundDeviceManager updateCharacteristicsE0:peripheral value:NO];
//    [m_boundDeviceManager updateCharacteristicsE5:peripheral value:NO];
//
//    [self changeStaus:statusDisconnected success:YES];
//    [self changeConnectStatus:ble_disconnect peripheral:peripheral];
//
//    if ([m_boundDeviceManager needReconnect:peripheral]) {
//        [self changeConnectStatus:ble_disconnect peripheral:peripheral];
//        usleep(10 * 1000);
//        [m_central connectPeripheral:peripheral options:nil];
//    }
//    else
//    {
//        [self changeConnectStatus:ble_unbind peripheral:peripheral];
//    }
}


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    DLog(@"");
#ifdef NEED_LOG_FILE
    WriteLog2(@"willRestoreState : %@\n", dict);
#endif
}

#pragma mark - Peripheral delegate


- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    DLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    DLog(@"");
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error
{
    DLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
//    DLog(@"");
    if (!error) {
        DLog(@"//step_ services : %@ found\r\n",
              peripheral.services);
//        m_bServiceFinished = YES;
        //触发获取所有特征值
        [self getAllCharacteristicsFromKeyfob:peripheral];
        DLog(@" Discovering Services Finished ! \r\n");
        
        NSNumber *n =  [NSNumber numberWithFloat:1.0];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: @"SERVICEFOUNDOVER" object: n];
    }
    else {
        DLog(@"Service discovery was unsuccessfull !\r\n");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{
    DLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    DLog(@"");
    static int index = 0 ;
    //    float f0 ;
    
    if (!error) {
        DLog(@"//step_10 Characteristics of service with UUID : %s found\r\n",
              [self CBUUIDToString:service.UUID]);
        index ++ ;
        
        for(int i=0; i < service.characteristics.count; i++) {
            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            [self SaveToActiveCharacteristic:c];
        }
        
        NSString *serviceStr = [NSString stringWithFormat:@"%s", [self CBUUIDToString:service.UUID]];
        if ([serviceStr isEqualToString:@"<FFE5>"] || [serviceStr isEqualToString:@"<ffe5>"]) {
            m_bCharacteristicsE5Finished = YES;
            [self useCharacteristic:service];

            [m_boundDeviceManager setWriteRespone:m_bWriteNoReponse peripheral:peripheral];

            [m_boundDeviceManager updateCharacteristicsE5:peripheral value:YES];
        }
        
        if ([serviceStr isEqualToString:@"<FFE0>"] || [serviceStr isEqualToString:@"<ffe0>"]) {
            m_bCharacteristicsE4Finished = YES;
            [self notification:0xFFE0 characteristicUUID:0xFFE4 p:peripheral on:YES];
            
//            [self useCharacteristic:service];
//            m_bWriteNoReponse = [peripheral canSendWriteWithoutResponse];
            
            [m_boundDeviceManager updateCharacteristicsE0:peripheral value:YES];
        }
        
        if (m_bCharacteristicsE4Finished && m_bCharacteristicsE5Finished) {
//            [self sendWakeupCode]; // deleted for more ble connect
//            [[BLEManager ShareInstance] startUpgrade:nil]; // for test

        }
    }
    else {
        DLog(@"Characteristic discorvery unsuccessfull !\r\n");
        index = 0 ;
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1800"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)//遍历此服务的所有特征值
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A04"]])
            {
                [peripheral readValueForCharacteristic:aChar];
                DLog(@"//step_10_y Found a Connection Parameters Characteristic");
                DLog(@"%@", aChar);
            }
        }
    }
    
#if 1
    NSArray *characteristics = [service characteristics];
    for (CBCharacteristic *characteristic in characteristics) {
//        NSLog(@" -- Characteristic %@ (%@)", [characteristic UUID], characteristic);
        
        switch ([self CBUUIDToInt:characteristic.UUID]) {
            case ORG_BLUETOOTH_CHARACTERISTIC_MANUFACTURER_NAME_STRING:
            case ORG_BLUETOOTH_CHARACTERISTIC_MODEL_NUMBER_STRING:
            case ORG_BLUETOOTH_CHARACTERISTIC_FIRMWARE_REVISION_STRING:
            case ORG_BLUETOOTH_CHARACTERISTIC_SOFTWARE_REVISION_STRING:
                [self readValue:service.UUID characteristicUUID:characteristic.UUID p:peripheral];
                break;
        }
    }
#endif
}



//
//- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral
//{
//    DLog(@"peripheralIsReadyToSendWriteWithoutResponse !!!!!");
////    [self sendTheBinding];
//}

-(void)useCharacteristic:(CBService *)service
{
    NSString *serviceStr = [NSString stringWithFormat:@"%s", [self CBUUIDToString:service.UUID]];
//    m_bWriteNoReponse = NO;
    if ([serviceStr isEqualToString:@"<FFE5>"] || [serviceStr isEqualToString:@"<ffe5>"])
    {
        NSInteger nCount = [service.characteristics count];
        for (NSInteger i = 0; i < nCount; i++) {
            CBCharacteristic *theChar = [service.characteristics objectAtIndex:i];
            CBCharacteristicProperties theProperty = (theChar.properties & CBCharacteristicPropertyWriteWithoutResponse);
            DLog(@"property = %ld", (long)theProperty);
            // CBCharacteristicPropertyWriteWithoutResponse
            // CBCharacteristicPropertyWrite
            if (theProperty == CBCharacteristicPropertyWriteWithoutResponse) {
                m_bWriteNoReponse = YES;
                break;
            }
        }
    }
}



-(void)getPeripheralResponseType:(CBPeripheral *)peripheral
{
    NSArray *servicesArr = peripheral.services;
    NSInteger nCount = [servicesArr count];
    for (NSInteger i = 0; i < nCount; i++) {
        CBService *theSer = [servicesArr objectAtIndex:i];
        NSString *serUUStr = [NSString stringWithFormat:@"%s", [self CBUUIDToString:theSer.UUID]];
        
        if ([serUUStr isEqualToString:@"<FFE5>"] || [serUUStr isEqualToString:@"<ffe5>"])
        {
            NSInteger nCount = [theSer.characteristics count];
            for (NSInteger i = 0; i < nCount; i++) {
                CBCharacteristic *theChar = [theSer.characteristics objectAtIndex:i];
                CBCharacteristicProperties theProperty = (theChar.properties & CBCharacteristicPropertyWriteWithoutResponse);

                if (theProperty == CBCharacteristicPropertyWriteWithoutResponse) {
                    m_bWriteNoReponse = YES;
//                    [m_boundDeviceManager setBindName:nil deviceName:nil peripheral:nil];
                }
            }
        }
    }
}




-(void)sendWakeupCode
{
#if PARALLEL_BIND
//    m_linkStatus = [m_boundDeviceManager ]
#endif
    if (m_linkStatus < statusWakingup) {
        m_linkStatus = statusWakingup;
        [self sendTheWakeup];
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_time_t delayTime1 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0/*延迟执行时间*/ * NSEC_PER_SEC));
    dispatch_after(delayTime1, dispatch_get_main_queue(), ^{
        typeof(self) theSelf = weakSelf;
        if(theSelf->m_linkStatus <= statusWakeup)
        {
            [self sendBindDeviceII];
        }
        else
        {
        }
    });
    

}


-(void) DisplayCharacteristicMessage:(CBCharacteristic *)c{
#if 1
    return;
#else
    DLog(@" service.UUID:%@ (%s)",c.service.UUID,[self CBUUIDToString:c.service.UUID]);
    DLog(@"         UUID:%@ (%s)",c.UUID,[self CBUUIDToString:c.UUID]);
    //    NSLog(@"   properties:0x%02x",c.properties);
    
    //    NSLog(@" value.length:%d",c.value.length);
    
    INT_STRUCT buf1;
    [c.value getBytes:&buf1 length:c.value.length];
    DLog(@"        value:");
    for(int i=0; i < c.value.length; i++) {
        DLog(@"%02x ",buf1.buff[i]&0x000000ff);
    }
    
    DLog(@"isBroadcasted:%d",c.isBroadcasted);
    DLog(@"  isNotifying:%d",c.isNotifying);
    
    NSString *provincName = [NSString stringWithFormat:@"%@", [self GetCharcteristicDiscriptorFromActiveDescriptorsArray:c]];
    
    DLog(@"   Discriptor:%@ ",provincName);
    
    //    NSLog(@"      :%@ ",c.UUID);
    //    NSLog(@"  UUID:%@ ",d.UUID);
    //    NSLog(@"    id:%@ ",d.value);
#endif
}

-(void) UpdateToActiveCharacteristic:(CBCharacteristic *)c{
    if (!m_activeCharacteristics)      //列表为空，第一次发现新设备
        NSLog(@"no characteristics !\r\n");
    
    for(int i = 0; i < m_activeCharacteristics.count; i++) {
        CBCharacteristic *p = [m_activeCharacteristics objectAtIndex:i];
        if (p.UUID == c.UUID) {
            [m_activeCharacteristics replaceObjectAtIndex:i withObject:c];
            //            NSLog(@"覆盖刷新 characteristic UUID %s\r\n",[self CBUUIDToString:p.UUID]);
            [self DisplayCharacteristicMessage:c];
            return ;
        }
    }
    
    DLog(@"Can't find this characteristics !\r\n");
}

-(BOOL) isAActiveCharacteristic:(CBCharacteristic *)c{
    for(int i = 0; i < m_activeCharacteristics.count; i++) {
        CBCharacteristic *p = [m_activeCharacteristics objectAtIndex:i];
        if (p.UUID == c.UUID) {
            return YES;
        }
    }
    DLog(@"^ isn't Active characteristics !\r\n");
    return NO;
}

-(void) SaveToActiveCharacteristic:(CBCharacteristic *)c{
    if (!m_activeCharacteristics){      //列表为空，第一次发现新设备
        m_activeCharacteristics = [[NSMutableArray alloc] initWithObjects:c,nil];
        //        NSLog(@"New characteristics, adding ... characteristic UUID %s",[self CBUUIDToString:c.UUID]);
    }
    else {                      //列表中有曾经发现的设备，如果重复发现则刷新，
        for(int i = 0; i < m_activeCharacteristics.count; i++) {
            CBCharacteristic *p = [m_activeCharacteristics objectAtIndex:i];
            if (p.UUID == c.UUID) {
                [m_activeCharacteristics replaceObjectAtIndex:i withObject:c];
                //                NSLog(@"覆盖 characteristic UUID %s",[self CBUUIDToString:p.UUID]);
                return ;
            }
        }
        //发现的外围设备，被保存在对象的peripherals 缓冲中
        [m_activeCharacteristics addObject:c];
        //        NSLog(@"New characteristics, adding ... characteristic UUID %s",[self CBUUIDToString:c.UUID]);
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"Value for %@ is %@", [characteristic UUID], [characteristic value]);
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (m_bUpgrade) {
        [self didUpgrade:characteristic];
        return;
    }
    else
    {
        [self getFirmwareVersion:characteristic];
    }
    if (!error) {
        if ([m_mode compare:@"UPDATEMODE" ] == NSOrderedSame)
        {
            
            //           NSLog(@"-----------特征值改变通知----------<<<<<<<<<<");//Jason++
            if ([self isAActiveCharacteristic:(characteristic)]==YES) {
                [self UpdateToActiveCharacteristic:characteristic];
                [nc postNotificationName: @"VALUECHANGUPDATE" object: characteristic];
                NSInteger nVer = [m_boundDeviceManager getDevVersion:peripheral];
                switch (nVer) {
                    case 0:
                    case 1:
                    {
                        [self addChange:characteristic peripheral:peripheral];
                    }
                        break;
                    case 2:
                    {
                        [self recvDeviceData:characteristic peripheral:peripheral];
                    }
                        break;
                    default:
                        break;
                }
            }
        }else if ([m_mode compare:@"SCANMODE" ] == NSOrderedSame){
            //            NSLog(@"-----------读取特征值的值之后值----------第3步结束");//Jason++
            //            if ([self isAActiveCharacteristic:(characteristic)]==YES) {
            //                [self SaveToActiveCharacteristic:characteristic];
            //                NSNumber *m =  [NSNumber numberWithFloat:0.75];
            //                [nc postNotificationName: @"DOWNLOADSERVICEPROCESSSTEP" object: m];
            //            }
            return;
        }else if ([m_mode compare:@"IDLEMODE" ] == NSOrderedSame){
            //            NSLog(@"-----------读取特征值的值之后值----------单独读");//Jason++
            if ([self isAActiveCharacteristic:(characteristic)]==YES) {
                [self SaveToActiveCharacteristic:characteristic];
                [nc postNotificationName: @"VALUECHANGUPDATE" object: Nil];
            }
        }
    }
    else {
        //        NSLog(@"Failed to read Characteristic UUID: %x", characteristicUUID);
        if ([m_mode compare:@"UPDATEMODE" ] == NSOrderedSame)
        {
            DLog(@"错误-----------特征值改变通知----------<<<<<<<<<<");//Jason++
        }else if ([m_mode compare:@"SCANMODE" ] == NSOrderedSame){
            DLog(@"错误---------读取特征值的值之后值----------第3步结束");//Jason++
            NSNumber *m =  [NSNumber numberWithFloat:0.75];
            [nc postNotificationName: @"DOWNLOADSERVICEPROCESSSTEP" object: m];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
//    DLog(@"error = %@", error);
    DLog(@"Data written: %@", error);
    if (!error) {
        if (m_bUpgrade) {
            if (step) {
//                step = nextStep;
                [self doStep];
            }
        }
    }
    else
    {
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    DLog(@"error = %@, character = %@", error, characteristic);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    DLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{
    DLog(@"");
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{
    DLog(@"");
}


#pragma makr - local notification

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
-(void)deviceLowPowerNotification
{
    if (@available(iOS 10.0, *)) {
        //    1.创建通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"提示";
        content.subtitle = @"";
        content.body = @"设备电量低";
        content.badge = @1;
        content.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"lowPower", @"lowPower", nil];
        
        //    NSError    *error    =    nil;
        //    2.设置声音
        UNNotificationSound
        *sound = [UNNotificationSound defaultSound];
        content.sound = sound;
        
        //    3.触发模式
        UNTimeIntervalNotificationTrigger  *trigger  = [UNTimeIntervalNotificationTrigger   triggerWithTimeInterval:1 repeats:NO];
        
        //    4.设置UNNotificationRequest
        NSString *requestIdentifer = @"BeeStarPower";
        UNNotificationRequest *request = [UNNotificationRequest
                                          requestWithIdentifier:requestIdentifer
                                          content:content
                                          trigger:trigger];
        
        //5.把通知加到UNUserNotificationCenter, 到指定触发点会被触发
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                               withCompletionHandler:^(NSError
                                                                                       *
                                                                                       _Nullable
                                                                                       error)
         {
             DLog(@"%@", error);
             
         }];
    }

}


-(void)localNotificationReq
{
    if (@available(iOS 10.0, *)) {
        
        //    1.创建通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"呼叫";
        content.subtitle = @"";
        content.body = @"设备正在呼叫手机";
        content.badge = @1;
        
        
        //    NSError    *error    =    nil;
        //    2.设置声音
        UNNotificationSound
        *sound = [UNNotificationSound defaultSound];
        content.sound = sound;
        
        //    3.触发模式
        UNTimeIntervalNotificationTrigger  *trigger  = [UNTimeIntervalNotificationTrigger   triggerWithTimeInterval:1 repeats:NO];
        
        //    4.设置UNNotificationRequest
        NSString *requestIdentifer = @"BeeStar";
        UNNotificationRequest *request = [UNNotificationRequest
                                          requestWithIdentifier:requestIdentifer
                                          content:content
                                          trigger:trigger];
        
        //5.把通知加到UNUserNotificationCenter, 到指定触发点会被触发
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                               withCompletionHandler:^(NSError
                                                                                       *
                                                                                       _Nullable
                                                                                       error)
         {
             DLog(@"%@", error);
             
         }];
    }
    
}
#else

-(void)addLocalNotification
{
    //定义本地通知对象
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    //设置调用时间
    //    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];//通知触发时间，1s之后
    notification.repeatInterval = 1; //通知重复次数
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    //设置通知属性
    notification.alertBody = @"设备正在呼叫手机";//通知主体
    notification.applicationIconBadgeNumber = 1;//应用程序右上角显示的未读消息数
    notification.alertAction = @"打开应用";//待机界面的滑动动作提示
    //    notification.alertLaunchImage = @"Default";//通过点击通知打开应用时的启动图片，这里使用程序启动图片
    notification.soundName=UILocalNotificationDefaultSoundName;//收到通知时播放的声音，默认消息声音

    //调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
}

-(void)removeNotification{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#endif

#pragma mark - upgrade
-(void)wouldUpdate
{
    m_bUpgrade = YES;
    [[BLEManager ShareInstance] startScan];
}

#if 0
-(void)discoverPeripheral:(CBPeripheral *)peri
{
    NSString *identiStr = peri.identifier.UUIDString;
    if([GlobalData shareData].m_uuidUpdate && [[GlobalData shareData].m_uuidUpdate isEqualToString:identiStr])
    {
        [self connectDevice:peri];
    }
    else
    {
//        m_bUpgrade = NO;
        DLog(@"");
    }
}
#endif


- (void) gpioScannerWithString:(NSString*)gpio toInt:(unsigned*)output {
    NSArray *values = [NSArray arrayWithObjects:@"0x00", @"0x01", @"0x02", @"0x03", @"0x04", @"0x05", @"0x06", @"0x07", @"0x10", @"0x11", @"0x12", @"0x13", @"0x20", @"0x21", @"0x22", @"0x23", @"0x24", @"0x25", @"0x26", @"0x27", @"0x28", @"0x29", @"0x30", @"0x31", @"0x32", @"0x33", @"0x34", @"0x35", @"0x36", @"0x37", nil];
    NSArray *titles = [NSArray arrayWithObjects:@"P0_0", @"P0_1", @"P0_2", @"P0_3", @"P0_4", @"P0_5", @"P0_6", @"P0_7", @"P1_0", @"P1_1", @"P1_2", @"P1_3", @"P2_0", @"P2_1", @"P2_2", @"P2_3", @"P2_4", @"P2_5", @"P2_6", @"P2_7", @"P2_8", @"P2_9", @"P3_0", @"P3_1", @"P3_2", @"P3_3", @"P3_4", @"P3_5", @"P3_6", @"P3_7", nil];
    
    for (int n=0; n<[values count]; n++) {
        if ([gpio isEqualToString:[titles objectAtIndex:n]]) {
            [[NSScanner scannerWithString:[values objectAtIndex:n]] scanHexInt:output];
        }
    }
}

-(void)setDeviceParam
{
    int blockSize;
    unsigned int spiMOSI, spiMISO, spiCS, spiSCK = 0;
    
    [self gpioScannerWithString:@"P0_5" toInt:&spiMISO];
    [self gpioScannerWithString:@"P0_6" toInt:&spiMOSI];
    [self gpioScannerWithString:@"P0_3" toInt:&spiCS];
    [self gpioScannerWithString:@"P0_0" toInt:&spiSCK];
    
    [self setMemoryType:MEM_TYPE_SUOTA_SPI];
    [self setSpiMOSIAddress:spiMOSI];
    [self setSpiMISOAddress:spiMISO];
    [self setSpiCSAddress:spiCS];
    [self setSpiSCKAddress:spiSCK];
    
    int memoryBank = 0;//(int) self.memoryBank.selectedSegmentIndex;
    [self setMemoryBank:memoryBank];
    
    [[NSScanner scannerWithString:@"240"] scanInt:&blockSize];
    [self setBlockSize:blockSize];
}


-(void)startUpgrade:(NSString *)filePath
{
    [self notificationWithUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_SERV_STATUS_UUID] p:m_curPeripheral on:YES];
    DLog(@"\ncurrent: %@\n", m_curPeripheral);
    BoundDevice *theDev = [m_boundDeviceManager getFocusDevice];
    DeviceStatusInfo *theInfo = [m_boundDeviceManager getDeviceInfo:theDev.m_UUIDstr];
    DLog(@"\nfocus: %@\n", theInfo.m_peri);
    
    m_bUpgrade = YES;
    [self setDeviceParam];
//    
//    fileManager *file = [[fileManager alloc] init];
//    NSString *curFilePath = [file getDocumentsPath];
//    if (filePath) {
//        curFilePath = [NSString stringWithFormat:@"%@", filePath];
//    }
//    NSData *retData = [file dataWithFilePath:curFilePath];
//    if (retData) {
//        fileData = [[NSMutableData alloc] initWithData:retData];
//        if (!fileData) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_UPDATE_STATUS object:@"0"];
//        }
//        step = 1;
//        [self doStep];
//    }
//    else
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_UPDATE_STATUS object:@"0"];
//        DLog(@"file data is nil");
//    }
}



- (void) doStep {
//   [self debug:[NSString stringWithFormat:@"*** Next step: %d", step]];
    DLog(@"%@", [NSString stringWithFormat:@"*** Next step: %d", step]);
    
    switch (step) {
        case 1: {
            // Step 1: Set memory type
            
            step = 0;
            expectedValue = 0x10;
            nextStep = 2;
            
            int _memDevData = (self.memoryType << 24) | (self.memoryBank & 0xFF);
//            [self debug:[NSString stringWithFormat:@"Sending data: %#10x", _memDevData]];
            DLog(@"%@", [NSString stringWithFormat:@"Sending data: %#10x", _memDevData]);
            NSData *memDevData = [NSData dataWithBytes:&_memDevData length:sizeof(int)];
            [self writeValueUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:m_curPeripheral data:memDevData];
            break;
        }
            
        case 2: {
            // Step 2: Set memory params
            int _memInfoData = 0;
            if (self.memoryType == MEM_TYPE_SUOTA_SPI) {
                _memInfoData = (self.spiMISOAddress << 24) | (self.spiMOSIAddress << 16) | (self.spiCSAddress << 8) | self.spiSCKAddress;
            } else if (self.memoryType == MEM_TYPE_SUOTA_I2C) {
                _memInfoData = (self.i2cAddress << 16) | (self.i2cSCLAddress << 8) | self.i2cSDAAddress;
            }
            else
            {
                _memInfoData = 0;
            }
//            [self debug:[NSString stringWithFormat:@"Sending data: %#10x", _memInfoData]];
            DLog(@"%@", [NSString stringWithFormat:@"Sending data: %#10x", _memInfoData]);
            NSData *memInfoData = [NSData dataWithBytes:&_memInfoData length:sizeof(int)];
            
            step = 3;
            nextStep = 3;
            [self writeValueUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_GPIO_MAP_UUID] p:m_curPeripheral data:memInfoData];
            break;
        }
            
        case 3: {
            // Load patch data
//            [self debug:[NSString stringWithFormat:@"Loading data from %@", [storage.file_url absoluteString]]];
//            fileData = [[NSData dataWithContentsOfURL:storage.file_url] mutableCopy];
            [self appendChecksum];
//            [self debug:[NSString stringWithFormat:@"Size: %d", (int) [fileData length]]];
            DLog(@"%@", [NSString stringWithFormat:@"Size: %d", (int) [fileData length]]);
            // Step 3: Set patch length
            chunkSize = 20;
            blockStartByte = 0;
            
            step = 4;
//            nextStep = 4;
            [self doStep];
            break;
        }
            
        case 4: {
            // Set patch length
            //UInt16 blockSizeLE = (blockSize & 0xFF) << 8 | (((blockSize & 0xFF00) >> 8) & 0xFF);
            
//            [self debug:[NSString stringWithFormat:@"Sending data: %#6x", blockSize]];
            DLog(@"%@", [NSString stringWithFormat:@"Sending data: %#6x", blockSize]);
            NSData *patchLengthData = [NSData dataWithBytes:&blockSize length:sizeof(UInt16)];
            
            step = 5;
//            nextStep = 5;
            [self writeValueUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_LEN_UUID] p:m_curPeripheral data:patchLengthData];
//            [self readValue:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_LEN_UUID] p:m_curPeripheral];
            break;
        }
            
        case 5: {
            // Send current block in chunks of 20 bytes
            step = 0;
            expectedValue = 0x02;
            nextStep = 5;
            
            int dataLength = (int) [fileData length];
            int chunkStartByte = 0;
            
            while (chunkStartByte < blockSize) {
                
                // Check if we have less than current block-size bytes remaining
                int bytesRemaining = blockSize - chunkStartByte;
                if (bytesRemaining < chunkSize) {
                    chunkSize = bytesRemaining;
                }
                
//                [self debug:[NSString stringWithFormat:@"Sending bytes %d to %d (%d/%d) of %d", blockStartByte + chunkStartByte, blockStartByte + chunkStartByte + chunkSize, chunkStartByte, blockSize, dataLength]];
                
                double progress = (double)(blockStartByte + chunkStartByte + chunkSize) / (double)dataLength;
//                [self.progressView setProgress:progress];
//                [self.progressTextLabel setText:[NSString stringWithFormat:@"%d%%", (int)(100 * progress)]];
                NSString *proStr = [NSString stringWithFormat:@"%d", (int)(100 * progress)];
//                DLog(@"progress = %@%%", proStr);
//                DLog(@"%@", [NSString stringWithFormat:@"Sending bytes %d to %d (%d/%d) of %d", blockStartByte + chunkStartByte, blockStartByte + chunkStartByte + chunkSize, chunkStartByte, blockSize, dataLength]);
//                NSString *proStr = [NSString stringWithFormat:@"%ld", nProgress];
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_PROGRESS object:proStr];
                // Step 4: Send next n bytes of the patch
                char bytes[chunkSize];
                [fileData getBytes:bytes range:NSMakeRange(blockStartByte + chunkStartByte, chunkSize)];
                NSData *byteData = [NSData dataWithBytes:&bytes length:sizeof(char)*chunkSize];
//                DLog(@"data: %@", byteData);
                // On to the chunk
                chunkStartByte += chunkSize;
                
                // Check if we are passing the current block
                if (chunkStartByte >= blockSize) {
                    // Prepare for next block
                    blockStartByte += blockSize;
                    
                    int bytesRemaining = dataLength - blockStartByte;
                    if (bytesRemaining == 0) {
                        nextStep = 6;
                        
                    } else if (bytesRemaining < blockSize) {
                        blockSize = bytesRemaining;
                        nextStep = 4; // Back to step 4, setting the patch length
                    }
                }
                
                [self writeValueWithoutResponse:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_DATA_UUID] p:m_curPeripheral data:byteData];
            }
            
            break;
        }
            
        case 6: {
            // Send SUOTA END command
            step = 0;
            expectedValue = 0x02;
            nextStep = 7;
            
            int suotaEnd = 0xFE000000;
//            [self debug:[NSString stringWithFormat:@"Sending data: %#10x", suotaEnd]];
            DLog(@"%@", [NSString stringWithFormat:@"Sending data: %#10x", suotaEnd]);
            NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(int)];
            [self writeValueUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:m_curPeripheral data:suotaEndData];
            break;
        }
            
        case 7: {
            // Wait for user to confirm reboot
            nextStep = 8;
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"固件已经更新" message:@"是否重启设备?" delegate:self cancelButtonTitle:@"不" otherButtonTitles:@"是的，重启", nil];
//            [alert setTag:UIALERTVIEW_TAG_REBOOT];
//            [alert show];
            break;
        }
            
        case 8: {
            // Go back to overview of devices
//            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
    }
}


//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (alertView.tag == UIALERTVIEW_TAG_REBOOT) {
//        if (buttonIndex != alertView.cancelButtonIndex) {
//            // Send reboot signal to device
//            step = 8;
//            int suotaEnd = 0xFD000000;
//            NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(int)];
//
//            [self writeValueUUID:[self IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:m_curPeripheral data:suotaEndData];
////            m_bUpgrade = NO;
//        }
//    }
//}

-(CBUUID *) IntToCBUUID:(UInt16)UUID {
    /*char t[16];
     t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
     NSData *data = [[NSData alloc] initWithBytes:t length:16];
     return [CBUUID UUIDWithData:data];
     */
    UInt16 cz = [self swap:UUID];
    NSData *cdz = [[NSData alloc] initWithBytes:(char *)&cz length:2];
    CBUUID *cuz = [CBUUID UUIDWithData:cdz];
    return cuz;
}


- (void) appendChecksum {
    uint8_t crc_code = 0;
    
    const char *bytes = [fileData bytes];
    for (int i = 0; i < [fileData length]; i++) {
        crc_code ^= bytes[i];
    }
    
//    [self debug:[NSString stringWithFormat:@"Checksum for file: %#4x", crc_code]];
    DLog(@"%@",[NSString stringWithFormat:@"Checksum for file: %#4x", crc_code]);
    [fileData appendBytes:&crc_code length:sizeof(uint8_t)];
}


- (void) writeValueUUID:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data andResponseType:(CBCharacteristicWriteType)responseType
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    if (!service) {
        DLog(@"Could not find service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        DLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    
//    NSLog(@"---data: %@, responseType:%ld", data, (long)responseType);
    [p writeValue:data forCharacteristic:characteristic type:responseType];
}


- (void) writeValueUUID:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    [self writeValueUUID:serviceUUID characteristicUUID:characteristicUUID p:p data:data andResponseType:CBCharacteristicWriteWithResponse];
}

- (void) writeValueWithoutResponse:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    [self writeValueUUID:serviceUUID characteristicUUID:characteristicUUID p:p data:data andResponseType:CBCharacteristicWriteWithoutResponse];
}



- (void) readValue: (CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p {
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    if (!service) {
        DLog(@"Could not find service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        DLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %@\r\n",[self CBUUIDToString:characteristicUUID],[self CBUUIDToString:serviceUUID], p.identifier);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}


-(void)getFirmwareVersion:(CBCharacteristic *)characteristic
{
    switch ([self CBUUIDToInt:characteristic.UUID]) {
        case ORG_BLUETOOTH_CHARACTERISTIC_MANUFACTURER_NAME_STRING: {
//            NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//            [containerView.manufacturerNameTextLabel setText:value];
            break;
        }
            
        case ORG_BLUETOOTH_CHARACTERISTIC_MODEL_NUMBER_STRING: {
//            NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//            [containerView.modelNumberTextLabel setText:value];
            break;
        }
            
        case ORG_BLUETOOTH_CHARACTERISTIC_FIRMWARE_REVISION_STRING: {
            NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//            [containerView.firmwareRevisionTextLabel setText:value];
            DLog(@"value : %@", value);
            [UserDefault setStringVaule:value key:USER_FIRMWARE_VERSION];
            break;
        }
            
        case ORG_BLUETOOTH_CHARACTERISTIC_SOFTWARE_REVISION_STRING: {
//            NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//            [containerView.softwareRevisionTextLabel setText:value];
            break;
        }
    }
}


-(void)didUpgrade:(CBCharacteristic *)characteristic
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SPOTA_SERV_STATUS_UUID]]) {
        char value;
        [characteristic.value getBytes:&value length:sizeof(char)];
        
        NSString *message = [self getErrorMessage:value];
        DLog(@"message = %@", message);
        
        if (expectedValue != 0) {
            // Check if value equals the expected value
            if (value == expectedValue) {
                // If so, continue with the next step
                step = nextStep;
                
                expectedValue = 0; // Reset
                
                [self doStep];
            } else {
                // Else display an error message
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alertView show];
                DLog(@"Error");
                expectedValue = 0; // Reset
//                [autoscrollTimer invalidate];
            }
        }
    }
}


- (NSString*) getErrorMessage:(SPOTA_STATUS_VALUES)status {
    NSString *message;
    
    switch (status) {
        case SPOTAR_SRV_STARTED:
            message = @"Valid memory device has been configured by initiator. No sleep state while in this mode";
            break;
            
        case SPOTAR_CMP_OK:
            message = @"SPOTA process completed successfully.";
            break;
            
        case SPOTAR_SRV_EXIT:
            message = @"Forced exit of SPOTAR service.";
            break;
            
        case SPOTAR_CRC_ERR:
            message = @"Overall Patch Data CRC failed";
            break;
            
        case SPOTAR_PATCH_LEN_ERR:
            message = @"Received patch Length not equal to PATCH_LEN characteristic value";
            break;
            
        case SPOTAR_EXT_MEM_WRITE_ERR:
            message = @"External Mem Error (Writing to external device failed)";
            break;
            
        case SPOTAR_INT_MEM_ERR:
            message = @"Internal Mem Error (not enough space for Patch)";
            break;
            
        case SPOTAR_INVAL_MEM_TYPE:
            message = @"Invalid memory device";
            break;
            
        case SPOTAR_APP_ERROR:
            message = @"Application error";
            break;
            
            // SUOTAR application specific error codes
        case SPOTAR_IMG_STARTED:
            message = @"SPOTA started for downloading image (SUOTA application)";
            break;
            
        case SPOTAR_INVAL_IMG_BANK:
            message = @"Invalid image bank";
            break;
            
        case SPOTAR_INVAL_IMG_HDR:
            message = @"Invalid image header";
            break;
            
        case SPOTAR_INVAL_IMG_SIZE:
            message = @"Invalid image size";
            break;
            
        case SPOTAR_INVAL_PRODUCT_HDR:
            message = @"Invalid product header";
            break;
            
        case SPOTAR_SAME_IMG_ERR:
            message = @"当前的版本相同";
            break;
            
        case SPOTAR_EXT_MEM_READ_ERR:
            message = @"Failed to read from external memory device";
            break;
            
        default:
            message = @"Unknown error";
            break;
    }
    
    return message;
}


-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:4];
    return ((b1[0] << 8) | b1[1]);
}

@end
