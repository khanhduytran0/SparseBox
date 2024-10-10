// https://github.com/Lakr233/BBackupp/blob/main/BBackupp/Backend/AppleMobileDevice

import Foundation

public typealias AnyCodableDictionary = [String: AnyCodable]

class MobileDevice {
    public static func deviceList() -> [String] {
        var deviceIdentifier = Set<String>()
        var dev_list: UnsafeMutablePointer<idevice_info_t?>?
        var count: Int32 = 0
        idevice_get_device_list_extended(&dev_list, &count)
        if let dev_list {
            for idx in 0 ..< Int(count) {
                if let udidCString = dev_list[idx]?.pointee.udid {
                    if let udid = String(cString: udidCString, encoding: .utf8) {
                        deviceIdentifier.insert(udid)
                    }
                }
            }
            idevice_device_list_extended_free(dev_list)
        }
        return Array(deviceIdentifier)
    }
    
    public static func requireDevice(
        udid: String,
        task: (idevice_t?) -> Void
    ) {
        var device: idevice_t?
        let ret = idevice_new_with_options(&device, udid, IDEVICE_LOOKUP_NETWORK)
        guard ret == IDEVICE_E_SUCCESS, let device else {
            task(nil)
            return
        }
        task(device)
        idevice_free(device)
    }
    
    public static func requireLockdownClient(
        device: idevice_t,
        name: String = UUID().uuidString,
        handshake: Bool = true,
        task: (lockdownd_client_t?) -> Void
    ) {
        var client: lockdownd_client_t?
        if handshake {
            guard lockdownd_client_new_with_handshake(device, &client, name) == LOCKDOWN_E_SUCCESS else {
                task(nil)
                return
            }
        } else {
            guard lockdownd_client_new(device, &client, name) == LOCKDOWN_E_SUCCESS else {
                task(nil)
                return
            }
        }
        guard let client else {
            task(nil)
            return
        }
        task(client)
        lockdownd_client_free(client)
    }
    
    public static func requireLockdownService(
        client: lockdownd_client_t,
        serviceName: String,
        requiresEscrowBag: Bool = false,
        task: (lockdownd_service_descriptor_t?) -> Void
    ) {
        var service: lockdownd_service_descriptor_t?
        if requiresEscrowBag {
            guard lockdownd_start_service_with_escrow_bag(client, serviceName, &service) == LOCKDOWN_E_SUCCESS,
                  let service
            else {
                task(nil)
                return
            }
            task(service)
            lockdownd_service_descriptor_free(service)
        } else {
            guard lockdownd_start_service(client, serviceName, &service) == LOCKDOWN_E_SUCCESS,
                  let service
            else {
                task(nil)
                return
            }
            task(service)
        }
    }
    
    public static func rebootDevice(udid: String) {
        requireDevice(udid: udid) { device in
            guard let device else {
                print("ERROR: Failed to requireDevice()")
                return
            }
            requireLockdownClient(device: device, handshake: true) { lkd_client in
                guard let lkd_client else {
                    print("ERROR: Failed to requireLockdownClient()")
                    return
                }
                let serviceName = "com.apple.mobile.diagnostics_relay"
                requireLockdownService(client: lkd_client, serviceName: serviceName, requiresEscrowBag: false) { lkd_service in
                    guard let lkd_service else {
                        print("ERROR: Failed to requireLockdownClient(\(serviceName)")
                        return
                    }
                    var diagnostics_client: diagnostics_relay_client_t?
                    diagnostics_relay_client_new(device, lkd_service, &diagnostics_client)
                    guard let diagnostics_client else {
                        print("ERROR: failed to create diagnostic service")
                        return
                    }
                    if diagnostics_relay_restart(diagnostics_client, DIAGNOSTICS_RELAY_ACTION_FLAG_NONE) != DIAGNOSTICS_RELAY_E_SUCCESS {
                        print("ERROR: Failed to reboot device")
                    }
                    diagnostics_relay_goodbye(diagnostics_client)
                    diagnostics_relay_client_free(diagnostics_client)
                }
            }
        }
    }
    
    static func requireInstallProxyService(
        device: idevice_t,
        name: String = UUID().uuidString,
        task: (instproxy_client_t?) -> Void
    ) {
        var client: instproxy_client_t?
        guard instproxy_client_start_service(device, &client, name) == INSTPROXY_E_SUCCESS,
              let client
        else {
            task(nil)
            return
        }
        task(client)
        instproxy_client_free(client)
    }
    
    static func listApplications(device: idevice_t) -> AnyCodableDictionary? {
        var applicationDic: AnyCodableDictionary = [:]
        var fullyDecoded = false
        requireInstallProxyService(device: device) { inst_client in
            guard let inst_client else { return }
            let options: [String: Any] = [
                "ApplicationType": "User",
                "ReturnAttributes": [
                    "CFBundleIdentifier",
                    "Path",
                ],
            ]
            let data = try! PropertyListEncoder().encode(AnyCodable(options))
            var query: plist_t?
            defer { plist_free(query) }
            _ = data.withUnsafeBytes { byte in
                plist_from_memory(byte.baseAddress, UInt32(byte.count), &query)
            }
            guard let query else { return }
            
            var apps: plist_t?
            defer { plist_free(apps) }
            
            instproxy_browse(inst_client, query, &apps)
            guard let apps, plist_get_node_type(apps) == PLIST_ARRAY else { return }
            
            var sb_client: sbservices_client_t?
            defer { if let sb_client { sbservices_client_free(sb_client) } }
            sbservices_client_start_service(device, &sb_client, UUID().uuidString)
            
            let appCount = plist_array_get_size(apps) // later just free apps, frees all
            for idx in 0 ..< appCount {
                // if any error, break entirely, none-fully-working backup is not acceptable
                guard let app_entry = plist_array_get_item(apps, idx),
                      plist_get_node_type(app_entry) == PLIST_DICT
                else { return }
                
                guard let bundleHandler = plist_dict_get_item(app_entry, "CFBundleIdentifier"),
                      plist_get_node_type(bundleHandler) == PLIST_STRING
                else { return }
                var buf: UnsafeMutablePointer<CChar>?
                defer { free(buf) }
                plist_get_string_val(bundleHandler, &buf)
                guard let buf else { return }
                let bundleIdentifier = String(cString: buf)
                
                guard let data = read_plist_to_binary_data(plist: app_entry),
                      var appElement = try? PropertyListDecoder().decode([String: AnyCodable].self, from: data)
                else { return }
                
                if let sb_client {
                    var buf: UnsafeMutablePointer<CChar>?
                    defer { free(buf) }
                    var len: UInt64 = 0
                    if sbservices_get_icon_pngdata(sb_client, bundleIdentifier, &buf, &len) == SBSERVICES_E_SUCCESS,
                       let buf,
                       len > 0
                    {
                        let pngData = Data(bytes: buf, count: Int(len))
                        appElement["PlaceholderIcon"] = .init(pngData)
                    }
                }
                
                applicationDic[bundleIdentifier] = .init(appElement)
            }
            
            fullyDecoded = true
        }
        guard fullyDecoded else { return nil }
        return applicationDic
    }
    
    static func listApplications(
        udid: String
    ) -> AnyCodableDictionary? {
        var result: AnyCodableDictionary?
        MobileDevice.requireDevice(udid: udid) { device in
            guard let device else { return }
            result = listApplications(device: device)
        }
        return result
    }
    
    /*
    func requireMobileBackup2Service(
        device: idevice_t,
        mobileBackup2Service: lockdownd_service_descriptor_t,
        task: (mobilebackup2_client_t?) -> Void
    ) {
        var client: mobilebackup2_client_t?
        guard mobilebackup2_client_new(device, mobileBackup2Service, &client) == MOBILEBACKUP2_E_SUCCESS,
              let client
        else {
            task(nil)
            return
        }
        task(client)
        mobilebackup2_client_free(client)
    }
    
    func requireAppleFileConduitService(
        device: idevice_t,
        appleFileConduitService: lockdownd_service_descriptor_t,
        task: (afc_client_t?) -> Void
    ) {
        var client: afc_client_t?
        guard afc_client_new(device, appleFileConduitService, &client) == AFC_E_SUCCESS,
              let client
        else {
            task(nil)
            return
        }
        task(client)
        afc_client_free(client)
    }
    
    func postNotification(
        lkd_client: lockdownd_client_t,
        notification: String
    ) {
        requireLockdownService(client: lkd_client, serviceName: NP_SERVICE_NAME, requiresEscrowBag: false) { np_service in
            guard let np_service else { return }
            var np: np_client_t?
            np_client_new(device, np_service, &np)
            guard let np else { return }
            np_post_notification(np, notification);
            np_client_free(np);
        })
    }
    
    func restoreBackup(
        udid: String,
        path: String
    ) {
        requireDevice(udid: udid, connection: connection) { device in
            guard let device else { return }
            requireLockdownClient(device: device, handshake: true) { lkd_client in
                guard let lkd_client else { return }
                postNotification(lkd_client: lkd_client, notification: NP_SYNC_WILL_START)
                requireAppleFileConduitService(device: device, appleFileConduitService: <#T##_#>, task: <#T##_#>)
                requireLockdownService(client: lkd_client, serviceName: MOBILEBACKUP2_SERVICE_NAME, requiresEscrowBag: true) { mb2_service in
                    guard let mb2_service else { return }
                    requireMobileBackup2Service(device: device, mobileBackup2Service: mb2_service) { mb2_client in
                        guard let mb2_client else { return }
                        
                        let options: [String: Codable] = [
                            "NewPassword": password,
                            "TargetIdentifier": udid,
                        ]
                        let data = try! PropertyListEncoder().encode(AnyCodable(options))
                        var query: plist_t?
                        defer { plist_free(query) }
                        _ = data.withUnsafeBytes { byte in
                            plist_from_memory(byte.baseAddress, UInt32(byte.count), &query, nil)
                        }
                        guard let query else { return }
                        mobilebackup2_send_message(mb2_client, "ChangePassword", query)
                    }
                }
            }
        }
    }
     */
}

private func read_plist_to_binary_data(plist: plist_t?) -> Data? {
    guard let plist else { return nil }
    var buf: UnsafeMutablePointer<CChar>?
    defer { free(buf) }
    var len: UInt32 = 0
    guard plist_to_bin(plist, &buf, &len) == PLIST_ERR_SUCCESS,
          let buf,
          len > 0
    else { return nil }
    return Data(bytes: buf, count: Int(len))
}
