//
//  mount1.m
//  StikDebug
//
//  Created by s s on 2025/12/6.
//
#include "mount.h"
#import "JITEnableContext.h"
#import "JITEnableContextInternal.h"
@import Foundation;

NSError* makeError(int code, NSString* msg);
size_t getMountedDeviceCount(IdeviceProviderHandle* provider, NSError** error) {
    ImageMounterHandle* client = 0;
    IdeviceFfiError* err = image_mounter_connect(provider, &client);
    if (err) {
        *error = makeError(err->code, @(err->message));
        idevice_error_free(err);
        return 0;
    }
    plist_t* devices;
    size_t deviceLength = 0;
    err = image_mounter_copy_devices(client, &devices, &deviceLength);
    if (err) {
        *error = makeError(err->code, @(err->message));
        idevice_error_free(err);
        return 0;
    }
    // no need to read the device, we just check the length
    for(int i = 0;i < deviceLength; ++i) {
        plist_free(devices[i]);
    }
    idevice_data_free((uint8_t *)devices, deviceLength*sizeof(plist_t));
    image_mounter_free(client);
    return deviceLength;
}


int mountPersonalDDI(IdeviceProviderHandle* provider, IdevicePairingFile* pairingFile2, NSString* imagePath, NSString* trustcachePath, NSString* manifestPath, NSError** error) {
    NSData* image = [NSData dataWithContentsOfFile:imagePath];
    NSData* trustcache = [NSData dataWithContentsOfFile:trustcachePath];
    NSData* buildManifest = [NSData dataWithContentsOfFile:manifestPath];
    if(!image || !trustcache || !buildManifest) {
        idevice_pairing_file_free(pairingFile2);
        *error = makeError(1, @"Failed to read one or more files");
        return 1;
    }
    
    LockdowndClientHandle* lockdownClient = 0;
    IdeviceFfiError* err = lockdownd_connect(provider, &lockdownClient);
    if (err) {
        *error = makeError(6, @(err->message));
        idevice_pairing_file_free(pairingFile2);
        idevice_error_free(err);
        return 6;
    }
    
    err = lockdownd_start_session(lockdownClient, pairingFile2);
    idevice_pairing_file_free(pairingFile2);
    if (err) {
        *error = makeError(7, @(err->message));
        idevice_error_free(err);
        return 7; // EC: 7
    }
    
    plist_t uniqueChipIDPlist = 0;
    err = lockdownd_get_value(lockdownClient, "UniqueChipID", 0, &uniqueChipIDPlist);
    if (err) {
        *error = makeError(8, @(err->message));
        idevice_error_free(err);
        return 8; // EC: 8
    }
    
    uint64_t uniqueChipID = 0;
    plist_get_uint_val(uniqueChipIDPlist, &uniqueChipID);
    
    ImageMounterHandle* mounterClient = 0;
    err = image_mounter_connect(provider, &mounterClient);
    if (err) {
        *error = makeError(9, @(err->message));
        idevice_error_free(err);
        return 9; // EC: 9
    }
    
    image_mounter_mount_personalized(
        mounterClient,
        provider,
        [image bytes],
        [image length],
        [trustcache bytes],
        [trustcache length],
        [buildManifest bytes],
        [buildManifest length],
        nil,
        uniqueChipID
                                     );
    
    if (err) {
        *error = makeError(10, @(err->message));
        idevice_error_free(err);
        return 10; // EC: 10
    }
    
    return 0;
}

@implementation JITEnableContext(DDI)
- (NSUInteger)getMountedDeviceCount:(NSError**)error {
    [self ensureHeartbeatWithError:error];
    if(*error) {
        return NO;
    }
    return getMountedDeviceCount(provider, error);
}
- (NSInteger)mountPersonalDDIWithImagePath:(NSString*)imagePath trustcachePath:(NSString*)trustcachePath manifestPath:(NSString*)manifestPath error:(NSError**)error {
    [self ensureHeartbeatWithError:error];
    if(*error) {
        return 0;
    }
    IdevicePairingFile* pairing = [self getPairingFileWithError:error];
    if(*error) {
        return 0;
    }
    return mountPersonalDDI(provider, pairing, imagePath, trustcachePath, manifestPath, error);
}
@end
