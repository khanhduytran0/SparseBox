//
//  afc.m
//  StikDebug
//
//  Created by Duy Tran on 2026/01/14.
//

#import "JITEnableContext.h"
#import "JITEnableContextInternal.h"
@import Foundation;

@implementation JITEnableContext(AFC)

- (BOOL)afcIsPathDirectory:(NSString *)path {
    if (!provider) {
        NSLog(@"Provider not initialized!");
        return NO;
    }
    struct AfcClientHandle *client = NULL;
    IdeviceFfiError* err = afc_client_connect(provider, &client);
    if (err) {
        return NO;
    }

    struct AfcFileInfo info;
    err = afc_get_file_info(client, path.fileSystemRepresentation, &info);
    BOOL is_dir = (info.st_ifmt && !strcmp(info.st_ifmt, "S_IFDIR"));
    afc_file_info_free(&info);

    afc_client_free(client);
    return is_dir;
}

- (NSArray<NSString *> *)afcListDir:(NSString *)path error:(NSError **)error {
    if (!provider) {
        NSLog(@"Provider not initialized!");
        *error = [self errorWithStr:@"Provider not initialized!" code:-1];
        return nil;
    }
    struct AfcClientHandle *client = NULL;
    IdeviceFfiError* err = afc_client_connect(provider, &client);
    if (err) {
        *error = [self errorWithStr:@"Failed to connect to AFC!" code:err->code];
        return nil;
    }

    char **entries = NULL;
    size_t count = 0;
    NSMutableArray<NSString *>* results = [NSMutableArray array];
    afc_list_directory(client, path.fileSystemRepresentation, &entries, &count);
    for (size_t i = 0; i < count; i++) {
        results[i] = @(entries[i]);
        free(entries[i]);
    }
    free(entries);

    afc_client_free(client);
    return results;
}

- (BOOL)afcPushFile:(NSString *)sourcePath toPath:(NSString *)destPath error:(NSError **)error {
    if (!provider) {
        NSLog(@"Provider not initialized!");
        *error = [self errorWithStr:@"Provider not initialized!" code:-1];
        return nil;
    }
    struct AfcClientHandle *client = NULL;
    IdeviceFfiError* err = afc_client_connect(provider, &client);
    if (err) {
        *error = [self errorWithStr:@"Failed to connect to AFC!" code:err->code];
        return nil;
    }

    struct AfcFileHandle *handle = NULL;
    err = afc_file_open(client, destPath.fileSystemRepresentation, AfcWrOnly, &handle);
    if (err) {
        *error = [self errorWithStr:@"Failed to open destination file on device!" code:err->code];
        afc_client_free(client);
        return NO;
    }

    NSData* fileData = [NSData dataWithContentsOfFile:sourcePath];
    afc_file_write(handle, fileData.bytes, fileData.length);
    afc_file_close(handle);

    afc_client_free(client);
    return YES;
}

@end
