import SwiftUI

@MainActor
struct RootView: View {
    @State private var permission = AudioRecordingPermission()

    var body: some View {
        if permission.isAllGranted {
            ProcessSelectionView()
        } else {
            VStack(spacing: 20) {
                // 顶部图标
                Image(systemName: "shield")
                    .resizable()
                    .frame(width: 60, height: 70)
                    .foregroundColor(.purple.opacity(0.8))
                
                // 标题
                Text("权限设置")
                    .font(.system(size: 24, weight: .medium))
                
                // 副标题
                Text("为确保软件正常运行，需要授予以下必要权限")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                // 权限列表
                VStack(spacing: 12) {
                    // 系统音频权限
                    permissionRow("授予系统音频权限", icon: "speaker.wave.2.fill", subtitle: "需要此权限以捕获来自对方的声音") {
                        switch permission.audioStatus {
                        case .unknown:
                            Button("允许") {
                                permission.request()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        case .authorized:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        case .denied:
                            Button("打开设置") {
                                NSWorkspace.shared.openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                    }
                    
                    // 麦克风权限
                    permissionRow("授予麦克风权限", icon: "mic.fill", subtitle: "需要此权限以捕获您的声音") {
                        switch permission.microphoneStatus {
                        case .unknown:
                            Button("允许") {
                                permission.request()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        case .authorized:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        case .denied:
                            Button("打开设置") {
                                NSWorkspace.shared.openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if permission.audioStatus == .denied || permission.microphoneStatus == .denied {
                    Text("提示：未授予必要权限将无法使用本软件")
                        .foregroundColor(.purple.opacity(0.8))
                        .font(.system(size: 12))
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Button("我需要帮助") {
                    // 帮助按钮操作
                }
                .buttonStyle(.link)
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 16))
            }
            .frame(width: 400)
            .padding(30)
        }
    }
    
    private func permissionRow(_ title: String, icon: String, subtitle: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .frame(width: 24)
                .foregroundColor(.purple.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            content()
        }
        .frame(height: 50)
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
