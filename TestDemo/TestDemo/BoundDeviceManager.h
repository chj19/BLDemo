//
//  BoundDeviceManager.h
//  Meteorological
//
//  Created by 徐守卫 on 2017/8/30.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

// 在绑定连接过程中，所处的阶段状态（连接，唤醒，绑定中，已绑定，断开等状态）
typedef NS_ENUM(NSInteger, statusLink)
{
    statusNone,
    statusDisconnected,
    statusConnected,
    statusWakingup,
    statusWakeup,
    statusBinding,
    statusBinded,
    statusGetVer,
    statusUnbinding,
    //    statusUnbound,
};

// 已经绑定后的状态, 是处于断开连接状态，还是连接状态
typedef NS_ENUM(NSInteger, connectStatus) {
    ble_connected,
    ble_disconnect,
    ble_unbind, 
};

// 已经绑定设备，用于存储
@interface BoundDevice : NSObject
//@property(nonatomic, strong)CBPeripheral *m_peripheral;
@property(nonatomic, strong)NSString *m_UUIDstr;
@property(nonatomic)BOOL m_bFoucsed;
@property(nonatomic, strong)NSString *m_deviceNameStr;
@property(nonatomic, strong)NSString *m_setNameStr;
@property(nonatomic)BOOL m_bManuDisconnect; // 用于添加多个蓝牙设备时，主动断开蓝牙设备，以便绑定其他蓝牙
@end

// 已经绑定的设备实时信息
@interface DeviceStatusInfo : NSObject
@property(nonatomic)connectStatus m_linkStatus; // 界面绑定状态
@property(nonatomic)statusLink m_bindStatus; // 绑定过程中的，各阶段状态
@property(nonatomic)BOOL m_bSrvE0;
@property(nonatomic)BOOL m_bSrvE5;
@property(nonatomic)CBPeripheral *m_peri;
@property(nonatomic)NSInteger m_nDevVersion;
@property(nonatomic)BOOL m_bWriteResponse;
@end


@interface WriteDataBuff : NSObject
@property(nonatomic, strong)NSString *m_UUIDStr;
@property(nonatomic, strong)NSData *m_msgData;
//@property(nonatomic)BOOL m_bNeedService;
//@property(nonatomic, strong)CBPeripheral *m_peripheral;
@end



@protocol BoundDeviceManagerDelegate <NSObject>

@optional
-(void)sendDataMessage:(NSData *)msgData peripheral:(CBPeripheral *)peri;
-(void)sendMessage:(NSString*)msgStr peripheral:(CBPeripheral *)peri;
-(void)sendTheWakeup;
-(void)sendWakeup:(CBPeripheral *)peripheral;

-(void)stopScan;
@end


// 主要用于绑定设备的数据保存和获取
@interface BoundDeviceManager : NSObject
@property(nonatomic, weak)id<BoundDeviceManagerDelegate> m_delegate;

-(void)discoverDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;

-(void)addPeripheral:(CBPeripheral *)peripheral;// 修改设备数据为绑定状态
-(void)removePeripheral:(CBPeripheral *)peripheral;// 删除绑定的设备
-(void)removeBound:(BoundDevice *)theDev;
-(BOOL)needReconnect:(CBPeripheral *)peripheral; // 判断该设备是否被移除，如果被移除，则为解绑断开，不需要重连
-(void)manuDisconnect:(CBPeripheral *)peripheral value:(BOOL)bManu; // 用于设置是否主动断开连接

-(void)connectedPeri:(CBPeripheral *)peripheral; // 修改设备数据为连接状态
-(void)disconnectPeri:(CBPeripheral *)peripheral; // 修改设备数据为断开状态
//-(void)didConnectedPeri:(CBPeripheral *)peripheral; // 保存刚连接上的设备

-(void)setBindingStatus:(CBPeripheral *)peripheral status:(statusLink)bindStatus;// 设置当前绑定中所处阶段
-(statusLink)getBindingStatus:(CBPeripheral *)peripheral;// 获取当前绑定所处阶段

-(NSInteger)getDevVersion:(CBPeripheral *)peri;
-(BOOL)getWriteResponse:(CBPeripheral *)peri;
-(void)setDevVersion:(NSInteger)nVer peripheral:(CBPeripheral *)peri;// 更新设备版本
-(void)setBindName:(NSString *)bindName deviceName:(NSString *)devName peripheral:(CBPeripheral *)peri; // 保存绑定到设备的物品名称
-(void)setWriteRespone:(BOOL)bWriteResponse peripheral:(CBPeripheral *)peri; // 该蓝牙写的时候，应该是写响应，还是写无响应

-(void)saveBoundDeviceDefault;
-(NSArray *)getBoundDeviceFromDefault;

-(BoundDevice *)getBoundDevice:(NSInteger)nIndex;
-(BoundDevice *)getBoundDeviceWithPeri:(CBPeripheral *)peripheral;
-(BoundDevice *)getFocusDevice;
-(DeviceStatusInfo *)getDeviceInfo:(NSString *)uuidStr;

// 写数据 No Service
-(void)updateService:(CBPeripheral *)peripheral; // 新的服务发现，通知更新。判断是否有对应的写缓存
-(void)writeDataNeedWait:(CBPeripheral *)peripheral message:(NSData *)msgData;

-(void)updateCharacteristicsE5:(CBPeripheral *)peri value:(BOOL)bFind;
-(void)updateCharacteristicsE0:(CBPeripheral *)peri value:(BOOL)bFind;
-(void)changeFocus:(CBPeripheral *)peri;
-(NSInteger)getFocusdDeviceIndex;

//
-(connectStatus)getFocusDevStatus;
-(void)changeDevStatus:(connectStatus)stautus peripheral:(CBPeripheral *)peri;
@end
