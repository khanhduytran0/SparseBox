//
//  mount.h
//  StikDebug
//
//  Created by s s on 2025/12/6.
//

#ifndef MOUNT_H
#define MOUNT_H
#include "idevice.h"
#include <Foundation/Foundation.h>
size_t getMountedDeviceCount(IdeviceProviderHandle* provider, NSError** error);
int mountPersonalDDI(IdeviceProviderHandle* provider, IdevicePairingFile* pairingFile2, NSString* imagePath, NSString* trustcachePath, NSString* manifestPath, NSError** error);
#endif
