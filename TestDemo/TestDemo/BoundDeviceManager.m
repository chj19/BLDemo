//
//  BoundDeviceManager.m
//  Meteorological
//
//  Created by 徐守卫 on 2017/8/30.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import "BoundDeviceManager.h"
#import "BLEManager.h"
#import "CommonFunc.h"
#import "UserDefault.h"

#define DEFAULT_UUIDSTR     @"DEFAULT_UUIDSTR"
#define DEFAULT_STATUS      @"DEFAULT_STATUS"
#define DEFAULT_NAME        @"DEFAULT_NAME"
#define DEFAULT_DEVICE_NAME     @"DEFAULT_DEVICE_NAME"


@implementation BoundDevice
{}

@end


@implementation DeviceStatusInfo



@end

@implementation WriteDataBuff



@end


@implementation BoundDeviceManager
{
//    NSMutableArray *m_peripheralArr; // searched peripheral
    NSMutableArray *m_boundDevice; // obj == BoundDevice
    NSMutableDictionary *m_boundPeriDic; // UUIDString == BoundDevice.m_UUIDStr : CBPeripheral
    
    NSMutableArray *m_writeWaitArr; // 在写的过程中，发现缺少Service时，加入写缓存。带获取到相应Service后，再重写数据； obj == WriteDataBuff
    NSInteger m_nCurPerIndex;
}
@synthesize m_delegate;

-(void)discoverDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (peripheral.name && [peripheral.name length] > 0) {

        NSString *UUIDString = [NSString stringWithFormat:@"%@", peripheral.identifier.UUIDString];
        if (m_boundDevice && [m_boundDevice count] > 0) {
            for(NSInteger i = 0; i < [m_boundDevice count]; i++)
            {
                BoundDevice *thePeri = [m_boundDevice objectAtIndex:i];
                if (thePeri && thePeri.m_UUIDstr) {
                    if ([UUIDString isEqualToString:thePeri.m_UUIDstr]) {
                        [[BLEManager ShareInstance] connectDevice:peripheral];
                        break;
                    }
                }
            }
        }
//        if (!m_peripheralArr) {
//            m_peripheralArr = [[NSMutableArray alloc] init];
//        }
        
//        DLog(@"searched peripheral: %@", peripheral);
//        [m_peripheralArr addObject:peripheralDic];
        
    }
    
    if ([self isAllConnected]) {
        if (m_delegate && [m_delegate respondsToSelector:@selector(stopScan)]) {
            [m_delegate stopScan];
        }
    }
}


-(BOOL)isAllConnected
{
    NSInteger nCount = [m_boundDevice count];
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        if (m_boundPeriDic) {
            DeviceStatusInfo *devStatus = [m_boundPeriDic objectForKey:theDev.m_UUIDstr];
            if (devStatus) {
                
                if (devStatus.m_linkStatus != ble_connected) {
                    return NO;
                }
            }
            else
            {
                return NO;
            }
            
        }
        else
        {
            return NO;
        }
    }
    
    return YES;
}


-(void)setBindingStatus:(CBPeripheral *)peripheral status:(statusLink)bindStatus
{
    if (peripheral) {
        NSString *uuidStr = peripheral.identifier.UUIDString;
        DeviceStatusInfo *theDic = [m_boundPeriDic objectForKey:uuidStr];
        if (theDic) {
            theDic.m_bindStatus = bindStatus;
        }
        else
        {
//            DLog(@"error!!!");
        }
    }
}

-(statusLink)getBindingStatus:(CBPeripheral *)peripheral
{
    if (peripheral) {
        NSString *uuidStr = peripheral.identifier.UUIDString;
        DeviceStatusInfo *theDic = [m_boundPeriDic objectForKey:uuidStr];
        if (theDic) {
            return theDic.m_bindStatus;
        }
    }
    
    return statusNone;
}



-(void)connectedPeri:(CBPeripheral *)peripheral
{ // 列表中设备连接状态依据
    if (peripheral) {
        NSString *uudiStr = peripheral.identifier.UUIDString;

        if (!m_boundPeriDic) {
            m_boundPeriDic = [[NSMutableDictionary alloc] init];
        }
        
        if (m_boundPeriDic) {
            DeviceStatusInfo *theDev = [m_boundPeriDic objectForKey:uudiStr];
            if (theDev) {
                theDev.m_linkStatus = ble_connected;
            }
            else
            {
                DeviceStatusInfo *theDecie = [[DeviceStatusInfo alloc] init];
                theDecie.m_linkStatus = ble_connected;
                theDecie.m_bindStatus = statusConnected;
                theDecie.m_bSrvE5 = NO;
                theDecie.m_bSrvE0 = NO;
                theDecie.m_peri = peripheral;
                [m_boundPeriDic setObject:theDecie forKey:uudiStr];
            }
        }
    }
}



-(void)didConnectedPeri:(CBPeripheral *)peripheral
{
    NSString *uudiStr = peripheral.identifier.UUIDString;
    if (!m_boundPeriDic) {
        m_boundPeriDic = [[NSMutableDictionary alloc] init];
    }
    
    if (m_boundPeriDic) {
        DeviceStatusInfo *theDev = [m_boundPeriDic objectForKey:uudiStr];
        if (theDev) {
            theDev.m_linkStatus = ble_connected;
        }
        else
        {
            DeviceStatusInfo *theDecie = [[DeviceStatusInfo alloc] init];
            theDecie.m_linkStatus = ble_connected;
            theDecie.m_bSrvE5 = NO;
            theDecie.m_bSrvE0 = NO;
            theDecie.m_peri = peripheral;
            [m_boundPeriDic setObject:theDecie forKey:uudiStr];
        }
    }

}


-(BOOL)getWriteResponse:(CBPeripheral *)peri
{
    NSString *uuidStr = peri.identifier.UUIDString;
    DeviceStatusInfo *dev = [m_boundPeriDic objectForKey:uuidStr];
    if (dev) {
        return dev.m_bWriteResponse;
    }
    
    return NO;
}

-(NSInteger)getDevVersion:(CBPeripheral *)peri
{
    NSString *uuidStr = peri.identifier.UUIDString;
    DeviceStatusInfo *dev = [m_boundPeriDic objectForKey:uuidStr];
    if (dev) {
        return dev.m_nDevVersion;
    }
    
    return 0;
}


-(void)setDevVersion:(NSInteger)nVer peripheral:(CBPeripheral *)peri// 更新设备版本
{
    NSString *uuidStr = peri.identifier.UUIDString;
    DeviceStatusInfo *dev = [m_boundPeriDic objectForKey:uuidStr];
    if (dev) {
        dev.m_nDevVersion = nVer;
    }
}

-(void)setWriteRespone:(BOOL)bWriteResponse peripheral:(CBPeripheral *)peri // 该蓝牙写的时候，应该是写响应，还是写无响应
{
    NSString *uuidStr = peri.identifier.UUIDString;
    DeviceStatusInfo *dev = [m_boundPeriDic objectForKey:uuidStr];
    if (dev) {
        dev.m_bWriteResponse = bWriteResponse;
    }
}


-(void)setBindName:(NSString *)bindName deviceName:(NSString *)devName peripheral:(CBPeripheral *)peri // 保存绑定到设备的物品名称
{
    NSString *uuidStr = peri.identifier.UUIDString;
    NSInteger nCount = [m_boundDevice count];
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        if (theDev && [uuidStr isEqualToString:theDev.m_UUIDstr]) {
            if (ISEMPTY(bindName) == NO) {
                theDev.m_setNameStr = [NSString stringWithFormat:@"%@", bindName];
            }
            if (ISEMPTY(devName) == NO) {
                theDev.m_deviceNameStr = [NSString stringWithFormat:@"%@", GET(devName)];
            }
            [self saveBoundDeviceDefault];
        }
    }
}


-(void)disconnectPeri:(CBPeripheral *)peripheral
{// 列表中设备连接状态依据
    if (peripheral) {
//        NSInteger nCount = [m_boundPeriInfo count];
        NSString *uudiStr = peripheral.identifier.UUIDString;

        
        DeviceStatusInfo *theDevic = [m_boundPeriDic objectForKey:uudiStr];
        if (theDevic) {
            theDevic.m_linkStatus = ble_disconnect;
        }

    }
}



-(void)saveBoundDeviceDefault
{
    if (m_boundDevice && [m_boundDevice count]) {
//        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:m_boundPeri];
//        [UserDefault saveBoundBle:m_boundDevice];
        
        NSMutableArray *dicArr = [[NSMutableArray alloc] init];
        if (m_boundDevice && dicArr) {
            NSInteger nCount = [m_boundDevice count];
            for (NSInteger i = 0; i < nCount; i++) {
                BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
                NSDictionary *theDic = [NSDictionary dictionaryWithObjectsAndKeys:theDev.m_UUIDstr, DEFAULT_UUIDSTR, theDev.m_bFoucsed == YES? @"1" :@"0", DEFAULT_STATUS, theDev.m_setNameStr, DEFAULT_NAME, theDev.m_deviceNameStr, DEFAULT_DEVICE_NAME, nil];
                [dicArr addObject:theDic];
            }
            [UserDefault saveBoundBle:dicArr];
        }
    }
}



-(NSArray *)getBoundDeviceFromDefault
{
    if (!m_boundDevice) {
        m_boundDevice = [[NSMutableArray alloc] init];
    }
    
    id BoundleDev = [UserDefault getBoundBle];
    if ([BoundleDev isKindOfClass:[NSArray class]]) {
        NSArray *tmpArr = (NSArray *)BoundleDev;
        if (tmpArr) {
            m_boundDevice = [[NSMutableArray alloc] initWithArray:tmpArr];
        }
    }
    else if([BoundleDev isKindOfClass:[NSData class]])
    {
        NSArray *tmpArr = [NSKeyedUnarchiver unarchiveObjectWithData:BoundleDev];
        if (tmpArr) {
            m_boundDevice = [[NSMutableArray alloc] initWithArray:tmpArr];
        }
    }
    else if([BoundleDev isKindOfClass:[NSString class]])
    {
        NSDictionary *theDic = [CommonFunc dictionaryWithJsonString:(NSString *)BoundleDev];
        NSArray *theArr = [theDic objectForKey:USER_BOUND_BLE];
        for (NSInteger i = 0; i < [theArr count]; i++) {
            NSDictionary *tmpDic = [theArr objectAtIndex:i];
            BoundDevice *tmpDev = [[BoundDevice alloc] init];
            tmpDev.m_bFoucsed = [[tmpDic objectForKey:DEFAULT_STATUS] boolValue];
            tmpDev.m_UUIDstr = [NSString stringWithFormat:@"%@", [tmpDic objectForKey:DEFAULT_UUIDSTR]];
            tmpDev.m_setNameStr = [NSString stringWithFormat:@"%@", [tmpDic objectForKey:DEFAULT_NAME]];
            tmpDev.m_deviceNameStr = [NSString stringWithFormat:@"%@", [tmpDic objectForKey:DEFAULT_DEVICE_NAME]];
            if (!m_boundDevice) {
                m_boundDevice = [[NSMutableArray alloc] init];
            }
            [m_boundDevice addObject:tmpDev];
        }
    }
//    [NSUserDefaults standardUserDefaults] setObject:m_boundPeri forKey:
    return m_boundDevice;
}


-(DeviceStatusInfo *)getDeviceInfo:(NSString *)uuidStr
{
    return [m_boundPeriDic objectForKey:uuidStr];
}


-(BoundDevice *)getBoundDevice:(NSInteger)nIndex
{
    NSInteger nCount = [m_boundDevice count];
    if (nIndex < nCount) {
        return [m_boundDevice objectAtIndex:nIndex];
    }
    
    return nil;
}


-(BoundDevice *)getBoundDeviceWithPeri:(CBPeripheral *)peripheral
{
    NSInteger nCount = [m_boundDevice count];
    NSString *theStr = peripheral.identifier.UUIDString;
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        if ([theStr isEqualToString:theDev.m_UUIDstr]) {
            return theDev;
        }
    }
    
    return nil;
}



-(void)focusDevice:(CBPeripheral *)peripheral
{
    BOOL bChange = NO;
    NSInteger nCount = [m_boundDevice count];
    NSString *devStr = peripheral.identifier.UUIDString;
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        if ([devStr isEqualToString:theDev.m_UUIDstr]) {
            bChange = YES;
        }
    }
    
    if (bChange) {
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
            if ([devStr isEqualToString:theDev.m_UUIDstr]) {
                theDev.m_bFoucsed = YES;
            }
            else
            {
                theDev.m_bFoucsed = NO;
            }
        }

        [self saveBoundDeviceDefault];
    }
}


-(BoundDevice *)getFocusDevice
{
    NSInteger nCount = [m_boundDevice count];
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        if (theDev.m_bFoucsed) {
            return theDev;
        }
    }
    
    if (nCount == 1) {
        return [m_boundDevice objectAtIndex:0];
    }
    
    return nil;
}



-(void)addPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral) {
        if (!m_boundDevice) {
            m_boundDevice = [[NSMutableArray alloc] init];
        }
        
        BOOL bNew = YES;
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDevice = [m_boundDevice objectAtIndex:i];
//            if ([[peripheral.identifier UUIDString] isEqualToString:[theDevice.m_peripheral.identifier UUIDString]])
            if ([[peripheral.identifier UUIDString] isEqualToString:theDevice.m_UUIDstr])
                {
//                m_boundPeri replaceObjectAtIndex:i withObject:
                bNew = NO;
//                theDevice.m_peripheral = peripheral;
//                theDevice.m_bFoucsed = YES;
//                theDevice.m_linkStatus = ble_connected;
            }
            else
            {
//                theDevice.m_linkStatus = ble_connected;
//                theDevice.m_bFoucsed = NO;
            }
        }
        
        if(bNew)
        {
            BoundDevice *newDevice = [[BoundDevice alloc] init];
            newDevice.m_bFoucsed = YES;
//            newDevice.m_peripheral = peripheral;
            newDevice.m_UUIDstr = [peripheral.identifier UUIDString];
//            newDevice.m_linkStatus = ble_connected;
            [m_boundDevice addObject:newDevice];
            
            // 将新绑定的设备信息保存
            NSMutableArray *dicArr = [[NSMutableArray alloc] init];
            if (m_boundDevice && dicArr) {
                NSInteger nCount = [m_boundDevice count];
                for (NSInteger i = 0; i < nCount; i++) {
                    BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
                    NSDictionary *theDic = [NSDictionary dictionaryWithObjectsAndKeys:theDev.m_UUIDstr, DEFAULT_UUIDSTR, theDev.m_bFoucsed == YES? @"1" :@"0", DEFAULT_STATUS, theDev.m_setNameStr, DEFAULT_NAME, theDev.m_deviceNameStr, DEFAULT_DEVICE_NAME, nil];
                    [dicArr addObject:theDic];
                }
                [UserDefault saveBoundBle:dicArr];
            }
        }
        
    }
}


-(void)removeBound:(BoundDevice *)theDev
{
    if (theDev) {
        
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDevice = [m_boundDevice objectAtIndex:i];
            if ([theDev.m_UUIDstr isEqualToString:theDevice.m_UUIDstr]) {
//                DLog(@"removed : %@", theDevice);
                [m_boundPeriDic removeObjectForKey:theDevice.m_UUIDstr];
                
                [m_boundDevice removeObjectAtIndex:i];
                
                break;
            }
        }
        
        NSMutableArray *dicArr = [[NSMutableArray alloc] init];
        if (m_boundDevice && dicArr) {
            NSInteger nCount = [m_boundDevice count];
            for (NSInteger i = 0; i < nCount; i++) {
                BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
                NSDictionary *theDic = [NSDictionary dictionaryWithObjectsAndKeys:theDev.m_UUIDstr, DEFAULT_UUIDSTR, theDev.m_bFoucsed == YES? @"1" :@"0", DEFAULT_STATUS, nil];
                [dicArr addObject:theDic];
            }
            [UserDefault saveBoundBle:dicArr];
        }
        else
        {
            return;
        }
    }
}

-(void)removePeripheral:(CBPeripheral *)peripheral
{
    if (peripheral) {
        if (!m_boundDevice) {
            m_boundDevice = [[NSMutableArray alloc] init];
        }
        
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDevice = [m_boundDevice objectAtIndex:i];
            if ([[peripheral.identifier UUIDString] isEqualToString:theDevice.m_UUIDstr]) {
//                DLog(@"removed : %@", theDevice);
                [m_boundPeriDic removeObjectForKey:theDevice.m_UUIDstr];
                
                [m_boundDevice removeObjectAtIndex:i];
                
                break;
            }
        }
        
        NSMutableArray *dicArr = [[NSMutableArray alloc] init];
        if (m_boundDevice && dicArr) {
            NSInteger nCount = [m_boundDevice count];
            for (NSInteger i = 0; i < nCount; i++) {
                BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
                NSDictionary *theDic = [NSDictionary dictionaryWithObjectsAndKeys:theDev.m_UUIDstr, DEFAULT_UUIDSTR, theDev.m_bFoucsed == YES? @"1" :@"0", DEFAULT_STATUS, nil];
                [dicArr addObject:theDic];
            }
            [UserDefault saveBoundBle:dicArr];
        }
        else
        {
            return;
        }
        
    }
}


-(void)manuDisconnect:(CBPeripheral *)peripheral value:(BOOL)bManu
{
    if(m_boundDevice && [m_boundDevice count] > 0)
    {
        NSString *uuidStr = peripheral.identifier.UUIDString;
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
            if ([theDev.m_UUIDstr isEqualToString:uuidStr]) {
                theDev.m_bManuDisconnect = bManu;
            }
        }
    }
}


-(BOOL)needReconnect:(CBPeripheral *)peripheral // 判断该设备是否被移除，如果被移除，则为解绑断开，不需要重连
{
    if(m_boundDevice && [m_boundDevice count] > 0)
    {
        NSString *uuidStr = peripheral.identifier.UUIDString;
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
            if ([theDev.m_UUIDstr isEqualToString:uuidStr] && theDev.m_bFoucsed /*&& NO == theDev.m_bManuDisconnect*/) {
                return YES;
            }
        }
    }
    
    return NO;
}

-(void)writeDataNeedWait:(CBPeripheral *)peripheral message:(NSData *)msgData
{
#if 1
    return;
#else
    // 需要等待设备再次连接以后再发送
    if (!m_writeWaitArr) {
        m_writeWaitArr = [[NSMutableArray alloc] init];
    }
    
    if ([m_writeWaitArr containsObject:msgData]) {
        return;
    }
    
    WriteDataBuff *theBuf = [[WriteDataBuff alloc] init];
    theBuf.m_UUIDStr = [NSString stringWithFormat:@"%@", peripheral.identifier.UUIDString];
    theBuf.m_msgData = [NSData dataWithData:msgData];
    [m_writeWaitArr addObject:theBuf];
#endif
}


-(void)updateService:(CBPeripheral *)peripheral
{
#if 0
    if (m_writeWaitArr) {
        NSInteger nCount = [m_writeWaitArr count];
        for (NSInteger i = 0; i < nCount; i++) {
            WriteDataBuff *theBuf = [m_writeWaitArr objectAtIndex:i];
            NSString *theStr = theBuf.m_UUIDStr;
            if ([theStr isEqualToString:peripheral.identifier.UUIDString]) {
                if (m_delegate && [m_delegate respondsToSelector:@selector(sendDataMessage:peripheral:)]) {
                    [m_delegate sendDataMessage:theBuf.m_msgData peripheral:peripheral];
                }
            }
        }
    }
#else
    if (m_delegate && [m_delegate respondsToSelector:@selector(sendMessage:peripheral:)]) {
//        [m_delegate sendMessage:@"FF" peripheral:peripheral];
        if (m_delegate && [m_delegate respondsToSelector:@selector(sendWakeup:)]) {
            [m_delegate sendWakeup:peripheral];
        }
    }
#endif
}



-(void)updateCharacteristicsE5:(CBPeripheral *)peri value:(BOOL)bFind
{
    if(peri)
    {
        NSString *uuidStr = peri.identifier.UUIDString;
        DeviceStatusInfo *theDevic = [m_boundPeriDic objectForKey:uuidStr];
        if (theDevic) {
            theDevic.m_bSrvE5 = bFind;
            
            if (theDevic.m_bSrvE0 && theDevic.m_bSrvE5) {
                [self performSelector:@selector(updateService:) withObject:peri afterDelay:0.5];
//                [self updateService:peri];
            }
        }
    }
}
//[self performSelector:@selector(getData) withObject:nil afterDelay:1.0];


-(void)updateCharacteristicsE0:(CBPeripheral *)peri value:(BOOL)bFind
{
    if(peri)
    {
        NSString *uuidStr = peri.identifier.UUIDString;
        DeviceStatusInfo *theDevic = [m_boundPeriDic objectForKey:uuidStr];
        if (theDevic) {
            theDevic.m_bSrvE0 = bFind;
            if (theDevic.m_bSrvE0 && theDevic.m_bSrvE5) {
//                [self updateService:peri];
                [self performSelector:@selector(updateService:) withObject:peri afterDelay:0.5];
            }
        }
    }
}

-(NSInteger)getFocusdDeviceIndex
{
    NSInteger nRet = -1;
    if (m_boundDevice && [m_boundDevice count]) {
        NSInteger nCount = [m_boundDevice count];
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
            if (theDev.m_bFoucsed) {
                nRet = i;
                break;
            }
        }
    }
    
    return nRet;
}



-(void)changeFocus:(CBPeripheral *)peri
{
    if (peri) {
        NSString *uuidStr = peri.identifier.UUIDString;
        NSInteger nCount = [m_boundDevice count];
        BOOL bFind = NO;
        NSInteger nIndex = 0;
        for (NSInteger i = 0; i < nCount; i++) {
            BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
            if ([uuidStr isEqualToString:theDev.m_UUIDstr]) {
                bFind = YES;
                nIndex = i;
                break;
            }
        }
        
        if (bFind) {
            for (NSInteger i = 0; i < nCount; i++) {
                BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
                if ([uuidStr isEqualToString:theDev.m_UUIDstr]) {
                    theDev.m_bFoucsed = YES;
                }
                else
                {
                    theDev.m_bFoucsed = NO;
                }
            }
        }
    }
}

-(connectStatus)getFocusDevStatus
{
    connectStatus bStatus = ble_unbind;
    NSInteger nCount = [m_boundDevice count];
    for (NSInteger i = 0; i < nCount; i++) {
        BoundDevice *theDev = [m_boundDevice objectAtIndex:i];
        NSString *uudiStr = theDev.m_UUIDstr;
        DeviceStatusInfo *dev = [m_boundPeriDic objectForKey:uudiStr];
        if (dev && theDev.m_bFoucsed) {
            return dev.m_linkStatus;
        }
        else if(theDev.m_bFoucsed)
        {
            bStatus = ble_disconnect;
            return bStatus;
        }
    }
    
    return bStatus;
}


-(void)changeDevStatus:(connectStatus)stautus peripheral:(CBPeripheral *)peri
{
    NSString *uuidStr = peri.identifier.UUIDString;
    DeviceStatusInfo *theInfo = [m_boundPeriDic objectForKey:uuidStr];
    if (theInfo) {
        theInfo.m_linkStatus = stautus;
        //    [m_boundPeriDic setObject:theInfo forKey:uuidStr];
        
        if (ble_unbind == stautus) {// 移除解绑的设备
            [m_boundPeriDic removeObjectForKey:uuidStr];
        }
    }
}

@end
