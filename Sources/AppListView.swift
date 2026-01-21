import SwiftUI

struct AppItemView: View {
    let appDetails: [String : Any]
    let bundleID: String
    let canLaunchWithLiquidGlass: Bool
    var body: some View {
        Form {
            Text("Version").badge(appDetails["CFBundleShortVersionString"] as? String ?? "unknown")
            NavigationLink {
                List {
                    ForEach(Array(appDetails.keys), id: \.self) { k in
                        let v = appDetails[k] as? String
                        VStack(alignment: .leading) {
                            Text(k)
                            Text(v ?? "(not a String)")
                                .font(.footnote)
                                .textSelection(.enabled)
                        }
                    }
                }
            } label: {
                Text("View full app details")
            }
            Section {
                Button("Launch") {
                    JITEnableContext.shared.launchAppWithoutDebug(bundleID, args: nil, logger: nil)
                }
                if canLaunchWithLiquidGlass {
                    Button("Launch with Liquid Glass (DOES NOT WORK)") {
                        let executablePath = "\(appDetails["Path"] as! String)/\(appDetails["CFBundleExecutable"] as! String)"
                        let args = [executablePath, "-com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck", "YES", "-com.apple.SwiftUI.IgnoreSolariumOptOut", "YES"]
                        JITEnableContext.shared.launchAppWithoutDebug(bundleID, args: args, logger: nil)
                    }
                }
            }
            Section {
                if let bundlePath = appDetails["Path"] {
                    Button("Copy app bundle folder") {
                        UIPasteboard.general.string = "file://a\(bundlePath)"
                    }
                }
                if let containerPath = appDetails["Container"] {
                    Button("Copy app data folder") {
                        UIPasteboard.general.string = "file://a\(containerPath)"
                    }
                }
            } header: {
                Text("Arbitrary read exploit")
            } footer: {
                Text("After copying path, open Settings, paste it in search bar, select all again and tap Share.\n\nOnly supported on iOS ≤ 18.2b1 and iOS 26.x. For this exploit, folders can only be shared via AirDrop.\nIf you're sharing App Store apps, please note that it will still remain encrypted.")
            }
        }
        .navigationTitle((appDetails["CFBundleName"] as? String) ?? bundleID)
    }

    init(bundleID: String) {
        self.bundleID = bundleID
        self.appDetails = ["Loading": AnyCodable("...")]
        self.canLaunchWithLiquidGlass = false
    }

    init(appDetails: [String: Any]) {
        self.appDetails = appDetails
        self.bundleID = (appDetails["CFBundleIdentifier"] as? String) ?? ""
        if #available(iOS 26, *) {
            let sdkName = appDetails["DTSDKName"] as? String ?? "iphoneos10.0"
            let forceOptOut = appDetails["UIDesignRequiresCompatibility"] as? Bool ?? false
            self.canLaunchWithLiquidGlass = sdkName.hasPrefix("iphoneos1") || forceOptOut
        } else {
            self.canLaunchWithLiquidGlass = false
        }
    }
}

struct AppListView: View {
    @State var apps: [String : [String : Any]] = [:]
    @State var appIcons: [String : UIImage] = [:]
    @State var searchString: String = ""
    @State var errorMessage: String? = nil

    var results: [String] {
        let filtered: [String]
        if searchString.isEmpty {
            filtered = Array(apps.keys)
        } else {
            filtered = apps.compactMap { key, appDetails in
                let appName = (appDetails["CFBundleName"] as? String)?.lowercased()
                let appPath = (appDetails["Path"] as? String)?.lowercased()
                let searchString = searchString.lowercased()
                return (appName!.contains(searchString) ||
                        appPath!.contains(searchString)) ? key : nil
            }
        }
        return filtered.sorted { a, b in
            let nameA = apps[a]!["CFBundleName"] as! String
            let nameB = apps[b]!["CFBundleName"] as! String
            return nameA < nameB
        }
    }

    var body: some View {
        VStack {
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 72))
                Text(errorMessage)
                    .padding()
            } else {
                List {
                    ForEach(results, id: \.self) { bundleID in
                        let appDetails = apps[bundleID]
                        let appName = (appDetails?["CFBundleName"] as? String) ?? ""
                        let appBundleID = (appDetails?["CFBundleIdentifier"] as? String) ?? ""
                        NavigationLink {
                            if let details = appDetails {
                                AppItemView(appDetails: details)
                            } else {
                                AppItemView(bundleID: bundleID)
                            }
                        } label: {
                            Image(uiImage: appIcons[bundleID] ?? UIImage(systemName: "app")!)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .task(id: bundleID) {
                                    guard appIcons[bundleID] == nil else { return }
                                    await MainActor.run {
                                        appIcons[bundleID] = UIImage(systemName: "app")
                                    }
                                    let icon = await Task.detached(priority: .background) {
                                        try? JITEnableContext.shared.getAppIcon(withBundleId: bundleID)
                                    }.value
                                    await MainActor.run {
                                        if let icon { appIcons[bundleID] = icon }
                                    }
                                }
                            VStack(alignment: .leading) {
                                Text(appName)
                                Text(appBundleID).font(Font.footnote)
                            }
                        }
                    }
                }
                .onAppear {
                    refresh()
                }
                .searchable(text: $searchString)
            }
        }
        .navigationTitle("App list")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    refresh()
                }
            }
        }
    }
    
    func refresh() {
        Task {
            do {
                apps = try JITEnableContext.shared.getAllAppsInfo() as! [String : [String : Any]]
            } catch {
                errorMessage = "Failed to get app list: \(error)"
            }
        }
    }
    
    init() {
        apps = ["Loading": [:]]
    }

}
