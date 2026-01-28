//
//  ProfileListView.swift
//  SparseBox
//
//  Created by Duy Tran on 21/01/25.
//

import Combine
import SwiftUI

struct ProfileItemView: View {
    let data: Data
    let details: [String : AnyHashable]
    
    var body: some View {
        Form {
            Section {
                Text("TeamName")
                    .badge(details["TeamName"] as? String ?? "unknown")
                Text("AppIDName")
                    .badge(details["AppIDName"] as? String ?? "unknown")
                Text("TeamID")
                    .badge((details["TeamIdentifier"] as? [String])?.first ?? "unknown")
                
                let expiryDate = (details["ExpirationDate"] as? Date) ?? Date(timeIntervalSince1970: 0)
                Text("Expires")
                    .badge(Text(expiryDate, format:
                            .relative(presentation: .named)))
                Text("Expiry Date")
                    .badge(Text(expiryDate, format: .dateTime.year().month().day().hour().minute()))
            } header: { Text("Info") }
            ShareLink(item: data, preview: SharePreview("embedded.mobileprovision")) {
                Text("Share provisioning profile")
            }
        }
    }
    
    init(data: Data, details: [String : AnyHashable]) {
        self.data = data
        self.details = details
    }
}

struct ProfileListView: View {
    @State var items: [Data: [String: AnyHashable]] = [:]
    @State var uuidToDelete: String? = nil
    @State var errorMessage: String? = nil
    @State var presentProfilePicker: Bool = false
    @State var presentDeleteConfirm = false
    
    var body: some View {
        VStack {
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 72))
                Text(errorMessage)
                    .padding()
            } else {
                List {
                    ForEach(Array(items.keys), id: \.self) { item in
                        let details = items[item]!
                        NavigationLink {
                            ProfileItemView(data: item, details: details)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(details["Name"] as? String ?? "unknown")
                                Text(details["AppIDName"] as? String ?? "unknown")
                                    .font(.footnote)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                uuidToDelete = details["UUID"] as? String ?? "unknown"
                                presentDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .alert("Are you sure you want to delete this item? The app associated with the provisioning profile will not launch anymore.",
                            isPresented: $presentDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let uuidToDelete {
                    do {
                        try JITEnableContext.shared.removeProfile(withUUID: uuidToDelete)
                        DispatchQueue.global().async {
                            refresh()
                        }
                    } catch {
                        errorMessage = "Failed to delete profile: \(error)"
                    }
                }
                uuidToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                uuidToDelete = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add", systemImage: "plus") {
                    presentProfilePicker.toggle()
                }
                .fileImporter(isPresented: $presentProfilePicker, allowedContentTypes: [.init(filenameExtension: "mobileprovision")!]) { result in
                    switch result {
                    case .success(let url):
                        do {
                            let data = try Data(contentsOf: url)
                            try JITEnableContext.shared.addProfile(data)
                            DispatchQueue.global().async {
                                refresh()
                            }
                        } catch {
                            errorMessage = "Failed to install profile: \(error)"
                        }
                    case .failure(let error):
                        errorMessage = "Failed to pick profile: \(error)"
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    errorMessage = nil
                    DispatchQueue.global().async {
                        refresh()
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.global().async {
                refresh()
            }
        }
        .navigationTitle("Provisioning profile list")
    }
    
    func refresh() {
        do {
            self.items = try JITEnableContext.shared.fetchAllProfiles().reduce([Data: [String: AnyHashable]]()) { (dict, item) in
                var dict = dict
                if let data = try? CMSDecoderHelper.decodeCMSData(item),
                   let profileDict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : AnyHashable] {
                    dict[data] = profileDict
                }
                return dict
            }.sorted { (lhs, rhs) in
                let lhsName = lhs.value["Name"] as? String ?? ""
                let rhsName = rhs.value["Name"] as? String ?? ""
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }.reduce(into: [Data: [String: AnyHashable]]()) { (dict, pair) in
                dict[pair.key] = pair.value
            }
        } catch {
            errorMessage = "Failed to get profiles: \(error)"
        }
    }
}
