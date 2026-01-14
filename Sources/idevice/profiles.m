//
//  profiles.m
//  StikDebug
//
//  Created by s s on 2025/11/29.
//
#include "profiles.h"
#import "JITEnableContext.h"
#import "JITEnableContextInternal.h"
@import Foundation;

NSError* makeError(int code, NSString* msg) {
    return [NSError errorWithDomain:@"profiles" code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
}


NSArray<NSData*>* fetchAppProfiles(IdeviceProviderHandle* provider, NSError** error) {
    MisagentClientHandle* misagentHandle = 0;
    IdeviceFfiError * err = misagent_connect(provider, &misagentHandle);
    if (err) {
        *error = makeError(err->code, @(err->message));
        idevice_error_free(err);
        return nil;
    }
    
    uint8_t** profileArr = 0;
    size_t profileCount = 0;
    size_t* profileLengthArr = 0;
    err = misagent_copy_all(misagentHandle, &profileArr, &profileLengthArr, &profileCount);

    if (err) {
        *error = makeError((err)->code, @((err)->message));
        misagent_client_free(misagentHandle);
        idevice_error_free(err);
        return nil;
    }
    
    NSMutableArray* ans = [NSMutableArray array];
    for(int i = 0; i < profileCount; ++i) {
        size_t len = profileLengthArr[i];
        uint8_t* profile = profileArr[i];
        NSData* profileData = [NSData dataWithBytes:profile length:len];

        [ans addObject:profileData];
    }
    
    misagent_free_profiles(profileArr, profileLengthArr, profileCount);
    misagent_client_free(misagentHandle);
    
    return ans;
}

bool removeProfile(IdeviceProviderHandle* provider, NSString* uuid, NSError** error) {
    MisagentClientHandle* misagentHandle = 0;
    IdeviceFfiError * err = misagent_connect(provider, &misagentHandle);
    if (err) {
        *error = makeError(err->code, @(err->message));
        idevice_error_free(err);
        return false;
    }
    
    err = misagent_remove(misagentHandle, [uuid UTF8String]);
    if (err) {
        *error = makeError((err)->code, @((err)->message));
        misagent_client_free(misagentHandle);
        idevice_error_free(err);
        return false;
    }
    
    misagent_client_free(misagentHandle);
    return true;
}

bool addProfile(IdeviceProviderHandle* provider, NSData* profile, NSError** error) {
    MisagentClientHandle* misagentHandle = 0;
    IdeviceFfiError * err = misagent_connect(provider, &misagentHandle);
    if (err) {
        *error = makeError(err->code, @(err->message));
        idevice_error_free(err);
        return false;
    }
    
    err = misagent_install(misagentHandle, [profile bytes], [profile length]);
    if (err) {
        *error = makeError((err)->code, @((err)->message));
        misagent_client_free(misagentHandle);
        idevice_error_free(err);
        return false;
    }
    
    misagent_client_free(misagentHandle);
    return true;
}

@implementation CMSDecoderHelper

+ (NSData*)decodeCMSData:(NSData *)cmsData
//             outCerts:(NSArray<id> * _Nullable * _Nullable)outCerts
                 error:(NSError * _Nullable * _Nullable)error
{
    if (!cmsData || cmsData.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSURLErrorBadURL
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid or empty CMS payload"}];
        }
        return nil;
    }

    NSData *xmlStart = [@"<?xml" dataUsingEncoding:NSASCIIStringEncoding];
    NSData *plistEnd = [@"</plist>" dataUsingEncoding:NSASCIIStringEncoding];
    NSData *binaryMagic = [@"bplist00" dataUsingEncoding:NSASCIIStringEncoding];

    if (xmlStart && plistEnd) {
        NSRange searchRange = NSMakeRange(0, cmsData.length);
        NSRange startRange = [cmsData rangeOfData:xmlStart options:0 range:searchRange];
        if (startRange.location != NSNotFound) {
            NSUInteger remainingLength = cmsData.length - startRange.location;
            NSRange endSearchRange = NSMakeRange(startRange.location, remainingLength);
            NSRange endRange = [cmsData rangeOfData:plistEnd options:0 range:endSearchRange];
            if (endRange.location != NSNotFound) {
                NSUInteger plistStart = startRange.location;
                NSUInteger plistEndIndex = NSMaxRange(endRange);
                if (plistEndIndex > plistStart && plistEndIndex <= cmsData.length) {
                    NSRange plistRange = NSMakeRange(plistStart, plistEndIndex - plistStart);
                    return [cmsData subdataWithRange:plistRange];
                }
            }
        }
    }

    if (binaryMagic) {
        NSRange binaryRange = [cmsData rangeOfData:binaryMagic options:0 range:NSMakeRange(0, cmsData.length)];
        if (binaryRange.location != NSNotFound) {
            NSRange plistRange = NSMakeRange(binaryRange.location, cmsData.length - binaryRange.location);
            return [cmsData subdataWithRange:plistRange];
        }
    }

    if (error) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:NSFileReadUnknownError
                                 userInfo:@{NSLocalizedDescriptionKey: @"Unable to extract plist from CMS payload"}];
    }
    return nil;
}

@end

@implementation JITEnableContext(Profile)

- (NSArray<NSData*>*)fetchAllProfiles:(NSError **)error {
    [self ensureHeartbeatWithError:error];
    if(*error) {
        return nil;
    }
    
    return fetchAppProfiles(provider, error);
}

- (BOOL)removeProfileWithUUID:(NSString*)uuid error:(NSError **)error {
    [self ensureHeartbeatWithError:error];
    if(*error) {
        return nil;
    }
    
    return removeProfile(provider, uuid, error);
}

- (BOOL)addProfile:(NSData*)profile error:(NSError **)error {
    [self ensureHeartbeatWithError:error];
    if(*error) {
        return nil;
    }
    return addProfile(provider, profile, error);
}


@end
