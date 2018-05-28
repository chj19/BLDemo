//
//  BLEManager.h
//  BeeStarDemo
//
//  Created by 徐守卫 on 2017/3/6.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEBLEModel.h"
#import "BleCodeDefine.h"
#import "BoundDeviceManager.h"
//#import "ParamaterStorage.h"
#import "GlobalData.h"

#define BLE_DEVICE_II       1
#define PARALLEL_BIND           1

#define SPOTA_SERVICE_UUID     0xFEF5
#define SPOTA_MEM_DEV_UUID     @"8082CAA8-41A6-4021-91C6-56F9B954CC34"
#define SPOTA_GPIO_MAP_UUID    @"724249F0-5EC3-4B5F-8804-42345AF08651"
#define SPOTA_MEM_INFO_UUID    @"6C53DB25-47A1-45FE-A022-7C92FB334FD4"
#define SPOTA_PATCH_LEN_UUID   @"9D84B9A3-000C-49D8-9183-855B673FDA31"
#define SPOTA_PATCH_DATA_UUID  @"457871E8-D516-4CA1-9116-57D0B17B9CB2"
#define SPOTA_SERV_STATUS_UUID @"5F78DF94-798C-46F5-990A-B3EB6A065C88"


#define ORG_BLUETOOTH_SERVICE_DEVICE_INFORMATION                    0x180A
#define ORG_BLUETOOTH_CHARACTERISTIC_MANUFACTURER_NAME_STRING       0x2A29
#define ORG_BLUETOOTH_CHARACTERISTIC_MODEL_NUMBER_STRING            0x2A24
#define ORG_BLUETOOTH_CHARACTERISTIC_SERIAL_NUMBER_STRING           0x2A25
#define ORG_BLUETOOTH_CHARACTERISTIC_HARDWARE_REVISION_STRING       0x2A27
#define ORG_BLUETOOTH_CHARACTERISTIC_FIRMWARE_REVISION_STRING       0x2A26
#define ORG_BLUETOOTH_CHARACTERISTIC_SOFTWARE_REVISION_STRING       0x2A28
#define ORG_BLUETOOTH_CHARACTERISTIC_SYSTEM_ID                      0x2A23
#define ORG_BLUETOOTH_CHARACTERISTIC_IEEE_11073                     0x2A2A
#define ORG_BLUETOOTH_CHARACTERISTIC_PNP_ID                         0x2A50


typedef NS_ENUM(NSInteger, recDataType)
{
    dataOther,
    dataHis,
    dataData,
};




@protocol BLEManagerDelegate <NSObject>
@optional
// viewController
-(void)discoverDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;

-(void)didConnectDevice:(CBPeripheral *)peripheral;
-(void)didConnectDeviceFailed:(CBPeripheral *)peripheral;

// PeripheralViewController
-(void)changeStatus:(statusLink)status;

-(void)changeDeviceStatus:(statusLink)status result:(BOOL)success;

-(void)updateData:(MEBLEModel *)data;

-(void)updateDeviceName:(NSString *)belName;

-(void)showAlert:(NSString *)title msg:(NSString *)messageStr;

-(void)showRecivedData:(NSString *)dataStr;

@end

@protocol BLEManagerRequireDelegate <NSObject>

@required

-(void)unbindDevice:(CBPeripheral *)peripheral;

@end





@interface BLEManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
@property(nonatomic, weak)id<BLEManagerDelegate> m_delegate;
@property(nonatomic, weak)id<BLEManagerRequireDelegate> m_requireDelegate;
@property(nonatomic, assign)statusLink m_linkStatus;
@property(nonatomic, assign)BOOL m_bEnterBackgroud;
@property(nonatomic, assign)BOOL m_bDeleteDevice;

@property char memoryType;
@property int memoryBank;
@property UInt16 blockSize;
@property int i2cAddress;
@property char i2cSDAAddress;
@property char i2cSCLAddress;

@property char spiMOSIAddress;
@property char spiMISOAddress;
@property char spiCSAddress;
@property char spiSCKAddress;

+(instancetype)ShareInstance;

-(void)initManager;
-(void)setDelegate:(id)viewController;
-(void)deleteDelegate;
-(BOOL)isPowerOn;

// 开始扫描
-(void)startScan;
-(void)stopScan;
-(BOOL)isScaning;

//连接设备
-(void)reconnectDevice;
- (void) connectDevice:(CBPeripheral *)peripheral;
-(void)connectDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData;
-(void)disconnectDevice;

//绑定设备
-(void)bindDevice:(CBPeripheral *)peripheral;
-(void)unbindDevice:(CBPeripheral *)peripheral;
-(void)setBindName:(NSString *)bindName; //用户指定的被绑定物品名称
-(void)setFocusPeri:(CBPeripheral *)peri;

-(void)discoverServices;
-(void)discoverServices:(CBPeripheral *)peri;
// send
-(void)sendTheWakeup;
-(void)sendWakeup:(CBPeripheral *)peripheral;
-(void)sendDataMessage:(NSString *)messageS;
-(void)sendMessage:(NSString *)msgStr peripheral:(CBPeripheral *)peri;
-(void)sendNewName:(NSString *)nameStr;
-(void)sendGuardMessage:(CBPeripheral *)peri;

-(void)getHistoryData;
-(void)cancelGetHistoryData;

//
-(void)modifyBindName:(NSString *)bindName;
-(void)modifyDevName:(NSString *)devName;
-(NSString *)getCurPeriName; // 当前绑定设备名称
-(NSString *)getCurBindName; // 当前绑定到设备的物品名称
-(connectStatus)getFocusDevStatus;
-(CBPeripheral *)getFocusDevice;
-(NSDictionary *)getDeviceData:(NSInteger)nRow;

-(void)setBindDisturb:(BOOL)bDisturb;

-(void)startUpgrade:(NSString *)filePath;
-(void)wouldUpdate;
@end
