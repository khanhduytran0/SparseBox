import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("PairingFile") var pairingFile: String?
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var lastError: String?
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        showPairingFileImporter.toggle()
                    } label: {
                        Text("Select pairing file")
                    }
                    .disabled(pairingFile != nil)
                    Button("[DEBUG] Reset pairing file") {
                        pairingFile = nil
                    }
                    .disabled(pairingFile == nil)
                } footer: {
                    if pairingFile != nil {
                        Text("Pairing file selected")
                    } else {
                        Text("Select a pairing file to continue")
                    }
                }
                Section {
                    Button("Apply test backup") {
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let file = documentsDirectory.appendingPathComponent("Manifest.mbdb", conformingTo: .data)
                        
                        var mbdb = MobileBackupDatabase(records: [
                            Directory(path: "", domain: "RootDomain").toRecord(),
                            Directory(path: "Library", domain: "RootDomain").toRecord(),
                            Directory(path: "Library/Preferences", domain: "RootDomain").toRecord()
                        ])
                        try! mbdb.toData().write(to: file)
                        
                        lastError = "Test error"
                        showErrorAlert.toggle()
                    }
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!], onCompletion: { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else {
                        return
                    }
                    pairingFile = try! String(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    startMinimuxer()
                case .failure(let error):
                    lastError = error.localizedDescription
                    showErrorAlert.toggle()
                }
            })
            .navigationTitle("SparseBox")
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(lastError ?? "???")
                /*
                if let data = try? Data(contentsOf: file) {
                    let a = Mbdb(data: data)
                    Text("\(a)")
                } else {
                    Text("File doesnt't exist at \(file)")
                }
                 */
            }
        }
        .onAppear {
            _ = start_emotional_damage("127.0.0.1:51820")
            if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String, altPairingFile.count > 5000 {
                pairingFile = altPairingFile
            }
            startMinimuxer()
        }
    }
    
    func startMinimuxer() {
        guard pairingFile != nil else {
            return
        }
        target_minimuxer_address()
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
            try start(pairingFile!, documentsDirectory)
        } catch {
            lastError = error.localizedDescription
            showErrorAlert.toggle()
        }
    }
}
