ARCHS := arm64
PACKAGE_FORMAT := ipa
TARGET := iphone:clang:latest:16.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SparseBox
LIBRARY_NAME = libEMProxy libimobiledevice

# Link em_proxy separately as it has duplicated symbols with minimuxer
libEMProxy_FILES = lib/empty.swift
libEMProxy_LDFLAGS = -force_load lib/libem_proxy-ios.a -install_name @rpath/libEMProxy.dylib
libEMProxy_FRAMEWORKS = Security
libEMProxy_INSTALL_PATH = /Applications/$(APPLICATION_NAME).app/Frameworks

# libimobiledevice + minimuxer
libimobiledevice_FILES = idevicebackup2.c
libimobiledevice_CFLAGS = -Iinclude
libimobiledevice_LDFLAGS = \
  -force_load lib/libimobiledevice-1.0.a \
  -force_load lib/libimobiledevice-glue-1.0.a \
  -force_load lib/libplist-2.0.a \
  -force_load lib/libusbmuxd-2.0.a \
  -force_load lib/libcrypto.a \
  -force_load lib/libssl.a \
  -force_load lib/libminimuxer-ios.a \
  -Wl,-mllvm,--opaque-pointers \
  -install_name @rpath/libimobiledevice.dylib
libimobiledevice_FRAMEWORKS = Foundation Security SystemConfiguration
libimobiledevice_INSTALL_PATH = /Applications/$(APPLICATION_NAME).app/Frameworks

SparseBox_FILES = \
  include/minimuxer-helpers.swift \
  include/minimuxer.swift \
  include/em_proxy.swift \
  include/SwiftBridgeCore.swift \
  Sources/SparseRestore/MBDB.swift \
  Sources/SparseRestore/Backup.swift \
  Sources/SparseRestore/Restore.swift \
  Sources/LogView.swift \
  Sources/MyApp.swift \
  Sources/MobileDevice/MobileDevice.swift \
  Sources/SwiftNIO/NIOFoundationCompat/ByteBuffer-foundation.swift \
  Sources/SwiftNIO/_NIOBase64/Base64.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-lengthPrefix.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-conversions.swift \
  Sources/SwiftNIO/NIOCore/IntegerTypes.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-multi-int.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-views.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-hexdump.swift \
  Sources/SwiftNIO/NIOCore/IntegerBitPacking.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-aux.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-core.swift \
  Sources/SwiftNIO/NIOCore/CircularBuffer.swift \
  Sources/SwiftNIO/NIOCore/ByteBuffer-int.swift \
  Sources/SwiftNIO/NIOPosix/PointerHelpers.swift \
  Sources/ContentView.swift
SparseBox_FRAMEWORKS = UIKit
SparseBox_CFLAGS = -fcommon -fobjc-arc
SparseBox_SWIFTFLAGS = -Iinclude -import-objc-header include/minimuxer-Bridging-Header.h
SparseBox_LDFLAGS = -L$(THEOS_OBJ_DIR) -rpath @executable_path/Frameworks
SparseBox_LIBRARIES = EMProxy imobiledevice
SparseBox_CODESIGN_FLAGS = -Sentitlements.plist
include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/application.mk
