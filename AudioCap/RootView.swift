import SwiftUI

@MainActor
struct RootView: View {
    @State private var permission = AudioRecordingPermission()

    var body: some View {
        Form {
            Section("Required Permissions") {
                if permission.isAllGranted {
                    LabeledContent("All Permissions Granted") {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    recordingView
                } else {
                    // 系统音频权限
                    LabeledContent("System Audio Recording") {
                        switch permission.audioStatus {
                        case .unknown:
                            Button("Allow") {
                                permission.request()
                            }
                        case .authorized:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .denied:
                            Button("Open Settings") {
                                NSWorkspace.shared.openSystemSettings()
                            }
                        }
                    }
                    
                    // 麦克风权限
                    LabeledContent("Microphone Access") {
                        switch permission.microphoneStatus {
                        case .unknown:
                            Button("Allow") {
                                permission.request()
                            }
                        case .authorized:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .denied:
                            Button("Open Settings") {
                                NSWorkspace.shared.openSystemSettings()
                            }
                        }
                    }
                    
                    // 权限说明
                    if permission.audioStatus == .denied || permission.microphoneStatus == .denied {
                        Text("Please grant both permissions to continue")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var recordingView: some View {
        ProcessSelectionView()
    }
}

extension NSWorkspace {
    func openSystemSettings() {
        guard let url = urlForApplication(withBundleIdentifier: "com.apple.systempreferences") else {
            assertionFailure("Failed to get System Settings app URL")
            return
        }
        openApplication(at: url, configuration: .init())
    }
}

#if DEBUG
#Preview {
    RootView()
}
#endif
