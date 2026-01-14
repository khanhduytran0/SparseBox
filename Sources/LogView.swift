import SwiftUI

class LogModel: ObservableObject {
    @Published var text = ""
    
    func append(_ msg: String) {
        text += msg
    }
}

let logPipe = Pipe()
let GLOBAL_LOG = LogModel()

struct LogView: View {
    @StateObject private var log = GLOBAL_LOG
    @State var ran = false
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(GLOBAL_LOG.text)
                    .font(.system(size: 12).monospaced())
                    .fixedSize(horizontal: false, vertical: false)
                    .textSelection(.enabled)
                Spacer()
                    .id(0)
            }
            .onAppear {
                guard !ran else { return }
                ran = true
                
                logPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let data = fileHandle.availableData
                    if !data.isEmpty, var logString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            if logString.contains(Utils.udid) {
                                logString = logString.replacingOccurrences(of: Utils.udid, with: "<redacted>")
                            }
                            log.append(logString)
                            proxy.scrollTo(0)
                        }
                    }
                }
            }
        }
    }
    
    init() {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
    }
}
