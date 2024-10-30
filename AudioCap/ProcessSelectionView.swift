import SwiftUI

@MainActor
struct ProcessSelectionView: View {
    @State private var processController = AudioProcessController()
    @State private var tap: ProcessTap?
    @State private var recorder: ProcessTapRecorder?
    @State private var selectedProcess: AudioProcess?
    
    var body: some View {
        VStack(spacing: 20) {
            // 系统声音选择
            VStack(alignment: .leading, spacing: 5) {
                Text("系统声音")
                    .font(.system(size: 16, weight: .medium))
                Text("选择用于采集会议声音的设备")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Process", selection: $selectedProcess) {
                        Text("选择应用...")
                            .tag(Optional<AudioProcess>.none)
                        
                        ForEach(processController.processes) { process in
                            HStack {
                                Image(nsImage: process.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                
                                Text(process.name)
                            }
                            .tag(Optional<AudioProcess>.some(process))
                        }
                    }
                    .disabled(recorder?.isRecording == true)
                    .task { processController.activate() }
                    .onChange(of: selectedProcess) { oldValue, newValue in
                        guard newValue != oldValue else { return }
                        
                        if let newValue {
                            setupRecording(for: newValue)
                        } else if oldValue == tap?.process {
                            teardownTap()
                        }
                    }
                    
                    Image(systemName: "waveform")
                        .foregroundColor(.purple)
                        .font(.system(size: 20))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // 声音传输服务状态
            VStack(alignment: .leading, spacing: 5) {
                Text("声音传输服务")
                    .font(.system(size: 16, weight: .medium))
                
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("服务运行中 | 服务端口: 1024")
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // 连接地址
            VStack(alignment: .leading, spacing: 5) {
                Text("连接地址")
                    .font(.system(size: 16, weight: .medium))
                Text("其他设备可通过此地址接收声音")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("192.168.3.29:10240")
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "qrcode")
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            if let tap {
                if let errorMessage = tap.errorMessage {
                    Text(errorMessage)
                        .font(.headline)
                        .foregroundStyle(.red)
                } else if let recorder {
                    RecordingView(recorder: recorder)
                        .onChange(of: recorder.isRecording) { wasRecording, isRecording in
                            if wasRecording, !isRecording {
                                createRecorder()
                            }
                        }
                }
            }
            
            Spacer()
            
            // 底部按钮
            HStack {
                Button("获取帮助") {
                    // 帮助操作
                }
                .buttonStyle(.link)
                .foregroundColor(.purple)
                
                Spacer()
                
                Button("打开网页应用") {
                    // 打开网页操作
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func setupRecording(for process: AudioProcess) {
        let newTap = ProcessTap(process: process)
        self.tap = newTap
        newTap.activate()
        
        createRecorder()
    }
    
    private func createRecorder() {
        guard let tap else { return }
        
        let filename = "\(tap.process.name)-\(Int(Date.now.timeIntervalSinceReferenceDate))"
        let audioFileURL = URL.applicationSupport.appendingPathComponent(filename, conformingTo: .wav)
        
        let newRecorder = ProcessTapRecorder(fileURL: audioFileURL, tap: tap)
        self.recorder = newRecorder
    }
    
    private func teardownTap() {
        tap = nil
    }
}

extension URL {
    static var applicationSupport: URL {
        do {
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let subdir = appSupport.appending(path: "AudioCap", directoryHint: .isDirectory)
            if !FileManager.default.fileExists(atPath: subdir.path) {
                try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
            }
            return subdir
        } catch {
            assertionFailure("Failed to get application support directory: \(error)")
            return FileManager.default.temporaryDirectory
        }
    }
}
