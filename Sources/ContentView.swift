import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("PairingFile") var pairingFile: String?
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var lastError: String?
    var body: some View {
        NavigationStack {
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
                    NavigationLink("Apply test backup") {
                        LogView()
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
            }
        }
        .onAppear {
            _ = start_emotional_damage("127.0.0.1:51820")
            if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String, altPairingFile.count > 5000, pairingFile == nil {
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
    
    public func withArrayOfCStrings<R>(
        _ args: [String],
        _ body: ([UnsafeMutablePointer<CChar>?]) -> R
    ) -> R {
        var cStrings = args.map { strdup($0) }
        cStrings.append(nil)
        defer {
            cStrings.forEach { free($0) }
        }
        return body(cStrings)
    }
}
