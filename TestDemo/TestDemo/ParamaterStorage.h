//
//  ParamaterStorage.h
//  SUOTA
//
//  Created by Martijn Houtman on 03/10/14.
//  Copyright (c) 2014 Martijn Houtman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
//#import "SUOTAServiceManager.h"
#import "Defines.h"

#if 0
typedef enum {
    SUOTA,
    SPOTA
} TYPE_SUOTA_OR_SPOTA;

typedef enum {
    MEM_TYPE_SUOTA_I2C            = 0x12,
    MEM_TYPE_SUOTA_SPI            = 0x13,
    MEM_TYPE_SPOTA_SYSTEM_RAM     = 0x00,
    MEM_TYPE_SPOTA_RETENTION_RAM  = 0x01,
    MEM_TYPE_SPOTA_I2C            = 0x02,
    MEM_TYPE_SPOTA_SPI            = 0x03
} MEM_TYPE;

typedef enum {
    P0_0 = 0x00,
    P0_1 = 0x01,
    P0_2 = 0x02,
    P0_3 = 0x03,
    P0_4 = 0x04,
    P0_5 = 0x05,
    P0_6 = 0x06,
    P0_7 = 0x07,
    P1_0 = 0x10,
    P1_1 = 0x11,
    P1_2 = 0x12,
    P1_3 = 0x13,
    P2_0 = 0x20,
    P2_1 = 0x21,
    P2_2 = 0x22,
    P2_3 = 0x23,
    P2_4 = 0x24,
    P2_5 = 0x25,
    P2_6 = 0x26,
    P2_7 = 0x27,
    P2_8 = 0x28,
    P2_9 = 0x29,
    P3_0 = 0x30,
    P3_1 = 0x31,
    P3_2 = 0x32,
    P3_3 = 0x33,
    P3_4 = 0x34,
    P3_5 = 0x35,
    P3_6 = 0x36,
    P3_7 = 0x37
} GPIO;

typedef enum {
    MEM_BANK_OLDEST = 0,
    MEM_BANK_1      = 1,
    MEM_BANK_2      = 2,
} MEM_BANK;

typedef enum {
    // Value zero must not be used !! Notifications are sent when status changes.
    SPOTAR_SRV_STARTED      = 0x01,     // Valid memory device has been configured by initiator. No sleep state while in this mode
    SPOTAR_CMP_OK           = 0x02,     // SPOTA process completed successfully.
    SPOTAR_SRV_EXIT         = 0x03,     // Forced exit of SPOTAR service.
    SPOTAR_CRC_ERR          = 0x04,     // Overall Patch Data CRC failed
    SPOTAR_PATCH_LEN_ERR    = 0x05,     // Received patch Length not equal to PATCH_LEN characteristic value
    SPOTAR_EXT_MEM_WRITE_ERR= 0x06,     // External Mem Error (Writing to external device failed)
    SPOTAR_INT_MEM_ERR      = 0x07,     // Internal Mem Error (not enough space for Patch)
    SPOTAR_INVAL_MEM_TYPE   = 0x08,     // Invalid memory device
    SPOTAR_APP_ERROR        = 0x09,     // Application error
    
    // SUOTAR application specific error codes
    SPOTAR_IMG_STARTED      = 0x10,     // SPOTA started for downloading image (SUOTA application)
    SPOTAR_INVAL_IMG_BANK   = 0x11,     // Invalid image bank
    SPOTAR_INVAL_IMG_HDR    = 0x12,     // Invalid image header
    SPOTAR_INVAL_IMG_SIZE   = 0x13,     // Invalid image size
    SPOTAR_INVAL_PRODUCT_HDR= 0x14,     // Invalid product header
    SPOTAR_SAME_IMG_ERR     = 0x15,     // Same Image Error
    SPOTAR_EXT_MEM_READ_ERR = 0x16,     // Failed to read from external memory device
    
} SPOTA_STATUS_VALUES;

#endif

@interface ParamaterStorage : NSObject

+ (ParamaterStorage*) getInstance;
- (id) init;

@property CBPeripheral *device;
//@property SUOTAServiceManager *manager;

@property NSURL *file_url;
@property TYPE_SUOTA_OR_SPOTA type;

@property MEM_TYPE mem_type;
@property MEM_BANK mem_bank;
@property UInt16 block_size;

@property UInt16 patch_base_address;
@property UInt16 i2c_device_address;
@property UInt32 spi_device_address; // Is actually 24 bits

@property GPIO gpio_scl;
@property GPIO gpio_sda;
@property GPIO gpio_miso;
@property GPIO gpio_mosi;
@property GPIO gpio_cs;
@property GPIO gpio_sck;


@end
