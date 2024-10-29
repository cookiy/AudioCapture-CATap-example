// main.swift
import Foundation
import CoreAudio
import AVFoundation

@available(macOS 14.2, *)
class AudioRecorder {
    private var tapDescription: CATapDescription?
    private var tap: AudioObjectID = 0
    private var audioFile: AVAudioFile?
    private var isRecording = false
    
    func startRecording() {
        guard !isRecording else { return }
        
        // 创建全局音频捕获
        let processes: [NSNumber] = [] // 空数组表示捕获所有进程
        tapDescription = CATapDescription(__stereoGlobalTapButExcludeProcesses: processes)
        
        guard let tapDescription = tapDescription else {
            print("Error creating tap description")
            return
        }

        // 配置 tap
        tapDescription.muteBehavior = .unmuted
        tapDescription.name = "AudioRecorderTap"
        tapDescription.isPrivate = true
        tapDescription.isExclusive = true
        
        // 创建进程 tap
        let status = AudioHardwareCreateProcessTap(tapDescription, &tap)
        guard status == noErr else {
            print("Error creating process tap: \(status)")
            return
        }
        

        // 创建录音文件
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent("recording.wav")

        do {
            // 创建音频格式
            guard let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48000,
                channels: 2,
                interleaved: true
            ) else {
                print("Error creating audio format")
                return
            }

            // 使用 audioFormat 的设置创建音频文件
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: audioFormat.settings
            )

            isRecording = true
            print("Recording started...")
            print("Recording file path: \(audioFileURL.path)")
        } catch {
            print("Error creating audio file: \(error)")
            cleanup()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        
        cleanup()
        print("Recording stopped")
    }
    
    private func cleanup() {
        if tap != 0 {
            AudioHardwareDestroyProcessTap(tap)
            tap = 0
        }
        
        audioFile = nil
        tapDescription = nil
        isRecording = false
    }
}

// 主程序入口
if #available(macOS 14.2, *) {
    let recorder = AudioRecorder()
    print("Press 's' to start recording, 'q' to stop and quit:")

    while let input = readLine()?.lowercased() {
        switch input {
        case "s":
            recorder.startRecording()
        case "q":
            recorder.stopRecording()
            exit(0)
        default:
            print("Invalid command")
        }
    }
} else {
    print("This program requires macOS 14.2 or later")
}