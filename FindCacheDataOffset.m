@import Foundation;
@import Darwin;
@import MachO;

__attribute__((constructor)) void FindCacheDataOffset() {
    /*
     * TL;DR: finding CacheData value offset is as follows:
     * - Get a pointer to the corresponding obfuscated key in libMobileGestalt
     * - Get a pointer to an unknown struct, whose first pointer is the pointer to the obfuscated key
     * - Offset it by 0x9a (FIXME this lol), read it as uint16_t
     * - Shift left the resulting offset by 3 bits
     */

    const struct mach_header_64 *header = NULL;
    const char *mgName = "/usr/lib/libMobileGestalt.dylib";
    const char *mgKey = "mtrAoWJ3gsq+I90ZnQ0vQw";
    dlopen(mgName, RTLD_GLOBAL);

    for (int i = 0; i < _dyld_image_count(); i++) {
        if (!strncmp(mgName, _dyld_get_image_name(i), strlen(mgName))) {
            header = (const struct mach_header_64 *)_dyld_get_image_header(i);
            break;
        }
    }
    assert(header);

    // Get a pointer to the corresponding obfuscated key in libMobileGestalt
    size_t textCStringSize;
    const char *textCStringSection = (const char *)getsectiondata(header, "__TEXT", "__cstring", &textCStringSize);
    for (size_t size = 0; size < textCStringSize; size += strlen(textCStringSection + size) + 1) {
        if (!strncmp(mgKey, textCStringSection + size, strlen(mgKey))) {
            textCStringSection += size;
            break;
        }
    }

    // Get a pointer to an unknown struct, whose first pointer is the pointer to the obfuscated key
    size_t constSize;
    // arm64e
    const uintptr_t *constSection = (const uintptr_t *)getsectiondata(header, "__AUTH_CONST", "__const", &constSize);
    if (!constSection) {
        // arm64, FIXME: is this correct?
        constSection = (const uintptr_t *)getsectiondata(header, "__DATA_CONST", "__const", &constSize);
    }
    for (int i = 0; i < constSize / 8; i++) {
        if (constSection[i] == (uintptr_t)textCStringSection) {
            constSection += i;
            break;
        }
    }

    // FIXME: is offset of offset consistent?
    off_t offset = (off_t)((uint16_t *)constSection)[0x9a/2] << 3;
    [NSUserDefaults.standardUserDefaults setInteger:offset forKey:@"MGCacheDataDeviceClassNumberOffset"];
}
