// Jackson Coxson
// heartbeat.c

#include "idevice.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/_types/_u_int64_t.h>
#include <CoreFoundation/CoreFoundation.h>
#include <limits.h>
#include "heartbeat.h"
#include <pthread.h>
@import Foundation;

int globalHeartbeatToken = 0;
NSDate* lastHeartbeatDate = nil;

void startHeartbeat(IdevicePairingFile* pairing_file, IdeviceProviderHandle** provider, int heartbeatToken, HeartbeatCompletionHandlerC completion) {
    IdeviceProviderHandle* newProvider = *provider;
    IdeviceFfiError* err = nil;

    // Create the socket address (replace with your device's IP)
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCKDOWN_PORT);
    
    NSString* deviceIP = [[NSUserDefaults standardUserDefaults] stringForKey:@"TunnelDeviceIP"];
    inet_pton(AF_INET, deviceIP ? [deviceIP UTF8String] : "10.7.0.1", &addr.sin_addr);
    
    
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing_file,
                                   "ExampleProvider", &newProvider);
    if (err != NULL) {
        fprintf(stderr, "Failed to create TCP provider: [%d] %s", err->code,
                err->message);
        completion(err->code, err->message);
        idevice_pairing_file_free(pairing_file);
        idevice_error_free(err);
        
        return;
    }
    
    // Connect to installation proxy
    HeartbeatClientHandle *client = NULL;
    err = heartbeat_connect(newProvider, &client);
    if (err != NULL) {
        fprintf(stderr, "Failed to connect to installation proxy: [%d] %s",
                err->code, err->message);
        completion(err->code, err->message);
        idevice_provider_free(newProvider);
        idevice_error_free(err);
        
        return;
    }
        

        *provider = newProvider;
    

    bool completionCalled = false;
    
    u_int64_t current_interval = 15;
    while (1) {
        // Get the new interval
        u_int64_t new_interval = 0;
        err = heartbeat_get_marco(client, current_interval, &new_interval);
        if (err != NULL) {
            fprintf(stderr, "Failed to get marco: [%d] %s token = %d, pthread_self = %p\n", err->code, err->message, heartbeatToken, pthread_self());
            if(!completionCalled) {
                completion(err->code, err->message);
            }
            heartbeat_client_free(client);
            idevice_error_free(err);
            return;
        }
        
        // if a new heartbeat thread is running we quit current one
        if (heartbeatToken != globalHeartbeatToken) {
            heartbeat_client_free(client);

            NSLog(@"Quitting %d, now token = %d", heartbeatToken, globalHeartbeatToken);
            return;
        }
        
        current_interval = new_interval + 5;
        
        // Reply
        err = heartbeat_send_polo(client);
        if (err != NULL) {
            fprintf(stderr, "Failed to get marco: [%d] %s", err->code, err->message);
            if(!completionCalled) {
                completion(err->code, err->message);
            }
            heartbeat_client_free(client);
            idevice_error_free(err);

            return;
        }
        
        if (lastHeartbeatDate && [[NSDate now] timeIntervalSinceDate:lastHeartbeatDate] > current_interval) {
            lastHeartbeatDate = nil;
//            NSLog(@"[SJ] Heartbeat marco receive timeout, probably disconnected, token = %d, pthread_self = %p", heartbeatToken, pthread_self());
            return;
        }
        lastHeartbeatDate = [NSDate now];
//        NSLog(@"[SJ] Heartbeat finished at %@, token = %d, pthread_self = %p", lastHeartbeatDate, heartbeatToken, pthread_self());


        if (!completionCalled) {
            completion(0, "Heartbeat succeeded");
        }
    }
}
