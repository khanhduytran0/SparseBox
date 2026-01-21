//
//  AFCBrowseView.swift
//  SparseBox
//
//  Created by Duy Tran on 13/12/25.
//

import Combine
import SwiftUI

enum SortOrder: Int {
    case pid = 0
    case path
    case name
}

struct ProcessItemView: View {
    let details: [String : Any]
    
    var body: some View {
        Form {
            Section {
                Text((details["pid"] as! NSNumber).stringValue)
                    .textSelection(.enabled)
            } header: { Text("PID") }
            Section {
                let path = URL(string: details["path"] as? String ?? "file://<unknown>")?.path() ?? "<unknown>"
                Text(path)
                    .textSelection(.enabled)
            } header: { Text("Path") }
            Section {
                Button("SIGSTOP - Stop") {
                    sendSignal(SIGSTOP)
                }
                Button("SIGCONT - Continue") {
                    sendSignal(SIGCONT)
                }
                Button("SIGTERM - Terminate") {
                    sendSignal(SIGTERM)
                }
                Button("SIGKILL - Kill") {
                    sendSignal(SIGKILL)
                }
            } header: { Text("Send signal") }
        }
    }
    
    func sendSignal(_ signal: Int32) {
        DispatchQueue.global().async {
            let pid = (details["pid"] as! NSNumber).int32Value
            try? JITEnableContext.shared.killProcess(withPID: pid, signal: signal)
        }
    }
    
    init(details: [String : Any]) {
        self.details = details
    }
}

struct ProcessListView: View {
    @State var items: [[String : AnyHashable]] = []
    @State var searchString: String = ""
    @State var errorMessage: String? = nil
    @State var timer: Timer?
    @State var sortOrder: SortOrder = .pid
    @State var sortReversed: Bool = false
    
    var results: [[String : AnyHashable]]  {
        let filtered: [[String : AnyHashable]]
        if searchString.isEmpty {
            filtered = items
        } else {
            filtered = items.filter { item in
                let pid = (item["pid"] as? NSNumber)?.stringValue ?? "-1"
                let path = URL(string: item["path"] as? String ?? "file://<unknown>")?.path().lowercased() ?? "<unknown>"
                let searchString = searchString.lowercased()
                return (pid.contains(searchString) ||
                        path.contains(searchString))
            }
        }
        return filtered.sorted { (a, b) -> Bool in
            switch sortOrder {
            case .pid:
                let pidA = (a["pid"] as? NSNumber)?.intValue ?? -1
                let pidB = (b["pid"] as? NSNumber)?.intValue ?? -1
                return sortReversed ? (pidA > pidB) : (pidA < pidB)
            case .path:
                let pathA = a["path"] as? String ?? ""
                let pathB = b["path"] as? String ?? ""
                return sortReversed ? (pathA > pathB) : (pathA < pathB)
            case .name:
                let pathA = (a["path"] as? NSString ?? "").lastPathComponent
                let pathB = (b["path"] as? NSString ?? "").lastPathComponent
                return sortReversed ? (pathA > pathB) : (pathA < pathB)
            }
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
                    ForEach(results, id: \.hashValue) { item in
                        let pid = (item["pid"] as! NSNumber).stringValue
                        let path = URL(string: item["path"] as? String ?? "file://<unknown>")?.path() ?? "<unknown>"
                        NavigationLink {
                            ProcessItemView(details: item)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(pid)
                                Text(path)
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
                .searchable(text: $searchString)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortOrder) {
                        Text("PID")
                            .tag(SortOrder.pid)
                        Text("Path")
                            .tag(SortOrder.path)
                        Text("Name")
                            .tag(SortOrder.name)
                    }
                    Toggle(isOn: $sortReversed) {
                        Label("Reverse order", systemImage: "arrow.up.arrow.down")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh", systemImage: "arrow.clockwise") {
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
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                DispatchQueue.global().async {
                    refresh()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationTitle("Process list")
    }
    
    func refresh() {
        do {
            self.items = (try JITEnableContext.shared.fetchProcessList() as! [[String : AnyHashable]])
        } catch {
            errorMessage = "Failed to get processes: \(error)"
        }
    }
}
