import SwiftUI

struct AppItemView: View {
    let appDetails: [String : AnyCodable]
    var body: some View {
        Form {
            Section {
                ForEach(Array(appDetails.keys), id: \.self) { k in
                    let v = appDetails[k]?.value as? String
                    Text(k)
                        .badge("\(v ?? "(null)" )")
                        .textSelection(.enabled)
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
                Text("After copying path, open Settings, paste it in search bar, select all again and tap Share.\n\nOnly supported on iOS 18.2b1 and older. For this exploit, folders can only be shared via AirDrop.\nIf you're sharing App Store apps, please note that it will still remain encrypted.")
            }
        }
    }
}

struct AppListView: View {
    @State var apps: [String : AnyCodable] = [:]
    @State var searchString: String = ""
    var results: [String] {
        Array(searchString.isEmpty ? apps.keys : apps.filter {
            let appDetails = $0.value.value as? [String: AnyCodable]
            let appName = (appDetails!["CFBundleName"]?.value as! String?)!
            let appPath = (appDetails!["Path"]?.value as! String?)!
            return appName.contains(searchString) || appPath.contains(searchString)
        }.keys)
    }
    var body: some View {
        List {
            ForEach(results, id: \.self) { bundleID in
                let value = apps[bundleID]
                let appDetails = value?.value as? [String: AnyCodable]
                let appImage = appDetails!["PlaceholderIcon"]?.value as! Data?
                let appName = (appDetails!["CFBundleName"]?.value as! String?)!
                let appPath = (appDetails!["Path"]?.value as! String?)!
                NavigationLink {
                    AppItemView(appDetails: appDetails!)
                } label: {
                    Image(uiImage: UIImage(data: appImage!)!)
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text(appName)
                        Text(appPath).font(Font.footnote)
                    }
                }
            }
        }
        .onAppear {
            if apps.count == 0 {
                Task {
                    let deviceList = MobileDevice.deviceList()
                    guard deviceList.count == 1 else {
                        print("Invalid device count: \(deviceList.count)")
                        return
                    }
                    let udid = deviceList.first!
                    apps = MobileDevice.listApplications(udid: udid)!
                }
            }
        }
        .searchable(text: $searchString)
        .navigationTitle("App list")
    }
}
