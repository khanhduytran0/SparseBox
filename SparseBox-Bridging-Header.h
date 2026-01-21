//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
@import UIKit;
#import "idevice.h"
#import "applist.h"
#import "profiles.h"
#import "JITEnableContext.h"

long FindCacheDataOffset(const char *mgKey);

#pragma mark - Private API

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)arg1 ;
@end
LSApplicationWorkspace *LSApplicationWorkspaceDefaultWorkspace(void);

@interface UIDevice(Private)
@property(nonatomic, strong, readonly) NSString *buildVersion;
+ (BOOL)_hasHomeButton;
@end
