//
//  JITEnableContext.m
//  StikJIT
//
//  Created by s s on 2025/3/28.
//
#include "idevice.h"
#include <arpa/inet.h>
#include <signal.h>
#include <stdlib.h>

#include "heartbeat.h"
#include "jit.h"
#include "applist.h"
#include "profiles.h"

#include "JITEnableContext.h"
//#import "StikDebug-Swift.h"
#include <os/lock.h>
#import <pthread.h>

static JITEnableContext* sharedJITContext = nil;

@implementation JITEnableContext {    
    int heartbeatToken;
    NSError* lastHeartbeatError;
    os_unfair_lock heartbeatLock;
    BOOL heartbeatRunning;
    dispatch_semaphore_t heartbeatSemaphore;

}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedJITContext = [[JITEnableContext alloc] init];
    });
    return sharedJITContext;
}

- (instancetype)init {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL* docPathUrl = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL* logURL = [docPathUrl URLByAppendingPathComponent:@"idevice_log.txt"];
    idevice_init_logger(Info, Debug, (char*)logURL.path.UTF8String);
    syslogQueue = dispatch_queue_create("com.stik.syslogrelay.queue", DISPATCH_QUEUE_SERIAL);
    syslogStreaming = NO;
    syslogClient = NULL;
    dispatch_queue_attr_t qosAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
    processInspectorQueue = dispatch_queue_create("com.stikdebug.processInspector", qosAttr);
    
    heartbeatToken = 0;
    heartbeatLock = OS_UNFAIR_LOCK_INIT;
    heartbeatRunning = NO;
    heartbeatSemaphore = NULL;
    lastHeartbeatError = nil;

    return self;
}

- (NSError*)errorWithStr:(NSString*)str code:(int)code {
    return [NSError errorWithDomain:@"StikJIT"
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: str }];
}

- (LogFuncC)createCLogger:(LogFunc)logger {
    return ^(const char* format, ...) {
        va_list args;
        va_start(args, format);
        NSString* fmt = [NSString stringWithCString:format encoding:NSASCIIStringEncoding];
        NSString* message = [[NSString alloc] initWithFormat:fmt arguments:args];
        NSLog(@"%@", message);

//        if ([message containsString:@"ERROR"] || [message containsString:@"Error"]) {
//            [[LogManagerBridge shared] addErrorLog:message];
//        } else if ([message containsString:@"WARNING"] || [message containsString:@"Warning"]) {
//            [[LogManagerBridge shared] addWarningLog:message];
//        } else if ([message containsString:@"DEBUG"]) {
//            [[LogManagerBridge shared] addDebugLog:message];
//        } else {
//            [[LogManagerBridge shared] addInfoLog:message];
//        }

        if (logger) {
            logger(message);
        }
        va_end(args);
    };
}

- (IdevicePairingFile*)getPairingFileWithError:(NSError**)error {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL* docPathUrl = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSString* currentDeviceUUIDStr = [NSUserDefaults.standardUserDefaults stringForKey:@"DeviceLibraryActiveDeviceID"];
    NSURL* pairingFileURL;
    if(!currentDeviceUUIDStr || [currentDeviceUUIDStr isEqualToString:@"00000000-0000-0000-0000-000000000001"]) {
        pairingFileURL = [docPathUrl URLByAppendingPathComponent:@"pairingFile.plist"];
    } else {
        pairingFileURL = [docPathUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"DeviceLibrary/Pairings/%@.mobiledevicepairing", currentDeviceUUIDStr]];
    }

    if (![fm fileExistsAtPath:pairingFileURL.path]) {
        NSLog(@"Pairing file not found!");
        *error = [self errorWithStr:@"Pairing file not found!" code:-17];
        return nil;
    }

    IdevicePairingFile* pairingFile = NULL;
    IdeviceFfiError* err = idevice_pairing_file_read(pairingFileURL.fileSystemRepresentation, &pairingFile);
    if (err) {
        *error = [self errorWithStr:@"Failed to read pairing file!" code:err->code];
        return nil;
    }
    return pairingFile;
}

- (IdeviceProviderHandle*)getTcpProviderHandle {
    return provider;
}

// only block until first heartbeat is completed or failed.
- (BOOL)startHeartbeat:(NSError**)err {
    os_unfair_lock_lock(&heartbeatLock);
    
    // If heartbeat is already running, wait for it to complete
    if (heartbeatRunning) {
        dispatch_semaphore_t waitSemaphore = heartbeatSemaphore;
        os_unfair_lock_unlock(&heartbeatLock);
        
        if (waitSemaphore) {
            dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_signal(waitSemaphore);
        }
        *err = lastHeartbeatError;
        return *err == nil;
    }
    
    // Mark heartbeat as running
    heartbeatRunning = YES;
    heartbeatSemaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_t completionSemaphore = heartbeatSemaphore;
    os_unfair_lock_unlock(&heartbeatLock);
    
    IdevicePairingFile* pairingFile = [self getPairingFileWithError:err];
    if (*err) {
        os_unfair_lock_lock(&heartbeatLock);
        heartbeatRunning = NO;
        heartbeatSemaphore = NULL;
        os_unfair_lock_unlock(&heartbeatLock);
        dispatch_semaphore_signal(completionSemaphore);
        return NO;
    }

    globalHeartbeatToken++;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block bool completionCalled = false;
    HeartbeatCompletionHandlerC Ccompletion = ^(int result, const char *message) {
        if(completionCalled) {
            return;
        }
        if (result != 0) {
            *err = [self errorWithStr:[NSString stringWithCString:message
                                                         encoding:NSASCIIStringEncoding] code:result];
            self->lastHeartbeatError = *err;
        } else {
            self->lastHeartbeatError = nil;
        }
        completionCalled = true;

        dispatch_semaphore_signal(semaphore);
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        startHeartbeat(
            pairingFile,
            &self->provider,
                       globalHeartbeatToken,Ccompletion
        );
    });
    // allow 5 seconds for heartbeat, otherwise we declare timeout
    intptr_t isTimeout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(5 * NSEC_PER_SEC)));
    if(isTimeout) {
        Ccompletion(-1, "Heartbeat failed to complete in reasonable time.");
    } else {
        NSLog(@"Start heartbeat success %p", pthread_self());
    }

    os_unfair_lock_lock(&heartbeatLock);
    heartbeatRunning = NO;
    heartbeatSemaphore = NULL;
    os_unfair_lock_unlock(&heartbeatLock);
    dispatch_semaphore_signal(completionSemaphore);
    
    return *err == nil;
}

- (BOOL)ensureHeartbeatWithError:(NSError**)err {
    // if it's 15s after last heartbeat, we restart heartbeat.
    if((!lastHeartbeatDate || [[NSDate now] timeIntervalSinceDate:lastHeartbeatDate] > 15)) {
        return [self startHeartbeat:err];
    }
    return YES;
}

- (BOOL)debugAppWithBundleID:(NSString*)bundleID logger:(LogFunc)logger jsCallback:(DebugAppCallback)jsCallback {
    NSError* err = nil;
    [self ensureHeartbeatWithError:&err];
    if(err) {
        logger(err.localizedDescription);
        return NO;
    }
    
    return debug_app(provider,
                     [bundleID UTF8String],
                     [self createCLogger:logger], jsCallback) == 0;
}

- (BOOL)debugAppWithPID:(int)pid logger:(LogFunc)logger jsCallback:(DebugAppCallback)jsCallback {
    NSError* err = nil;
    [self ensureHeartbeatWithError:&err];
    if(err) {
        logger(err.localizedDescription);
        return NO;
    }
    
    return debug_app_pid(provider,
                     pid,
                     [self createCLogger:logger], jsCallback) == 0;
}





- (void)dealloc {
    [self stopSyslogRelay];
    if (provider) {
        idevice_provider_free(provider);
    }
}





@end
