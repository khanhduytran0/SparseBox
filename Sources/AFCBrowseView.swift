//
//  AFCBrowseView.swift
//  SparseBox
//
//  Created by Duy Tran on 13/12/25.
//

import SwiftUI

struct AFCBrowseView: View {
    @State var fsRootPath: String = "/var/mobile/Media"
    @State var afcPath: String
    @State var items: [String : Bool] = [:] // path, isDirectory
    
    var body: some View {
        
        List {
            ForEach(Array(items.keys), id: \.self) { item in
                let isDir = items[item] as? Bool ?? false
                NavigationLink {
                    let newAFCPath = (afcPath as NSString).appendingPathComponent(item)
                    if isDir {
                        AFCBrowseView(afcPath: newAFCPath)
                    } else {
                        Text("File: \(item) at path \(newAFCPath)")
                    }
                } label: {
                    HStack {
                        Image(systemName: isDir ? "folder.fill" : "doc.text")
                        Text(item)
                    }
                }
            }
        }
        .navigationTitle(
            afcPath == "/" ? fsRootPath :
            (afcPath as NSString).lastPathComponent
        )
        .onAppear {
            print("Loading AFC path: \(afcPath)")
            DispatchQueue.global().async {
                let result = try? JITEnableContext.shared.afcListDir(afcPath)
                    .dropFirst(2) // skip . and ..
                    .sorted()
                    .compactMap { item in
                        let fullPath = (afcPath as NSString).appendingPathComponent(item)
                        let isDir = JITEnableContext.shared.afcIsPathDirectory(fullPath) ?? false
                        return (item, isDir)
                    }
                DispatchQueue.main.async {
                    self.items = result?
                        .reduce(into: [String : Bool]()) { dict, pair in
                            dict[pair.0] = pair.1
                        } ?? [:]
                }
            }
        }
    }
    
    init() {
        self.init(afcPath: "/")
    }
    
    init(afcPath: String) {
        self.afcPath = afcPath
        items = ["Loading..." : false]
    }
}
