//
//  jit.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

// jit.h
#ifndef JIT_H
#define JIT_H
#include "idevice.h"

typedef void (^LogFuncC)(const char* message, ...);
typedef void (^DebugAppCallback)(int pid,
                                 struct DebugProxyHandle* debug_proxy,
                                 struct RemoteServerHandle* remote_server,
                                 dispatch_semaphore_t semaphore);
int debug_app(IdeviceProviderHandle* tcp_provider, const char *bundle_id, LogFuncC logger, DebugAppCallback callback);
int debug_app_pid(IdeviceProviderHandle* tcp_provider, int pid, LogFuncC logger, DebugAppCallback callback);
int launch_app_via_proxy(IdeviceProviderHandle* tcp_provider, const char *bundle_id, int argc, const char* const* argv, LogFuncC logger);

#endif /* JIT_H */
