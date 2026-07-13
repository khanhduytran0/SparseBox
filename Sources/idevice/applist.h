//
//  applist.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

#ifndef APPLIST_H
#define APPLIST_H
@import Foundation;
@import UIKit;

NSDictionary<NSString*, NSString*>* list_installed_apps(AdapterHandle* adapter, RsdHandshakeHandle* handshake, NSString** error);
NSDictionary<NSString*, NSString*>* list_all_apps(AdapterHandle* adapter, RsdHandshakeHandle* handshake, NSString** error);
NSDictionary<NSString*, NSString*>* list_hidden_system_apps(AdapterHandle* adapter, RsdHandshakeHandle* handshake, NSString** error);
UIImage* getAppIcon(AdapterHandle* adapter, RsdHandshakeHandle* handshake, NSString* bundleID, NSString** error);
NSDictionary *getAllAppsInfo(AdapterHandle* adapter, RsdHandshakeHandle* handshake, NSString **error);
id plist_to_objc_object(plist_t plist);

#endif /* APPLIST_H */
