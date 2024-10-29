import SwiftUI
import Observation
import OSLog
import AVFoundation

@Observable
final class AudioRecordingPermission {
    private let logger = Logger(subsystem: kAppSubsystem, category: String(describing: AudioRecordingPermission.self))

    enum Status: String {
        case unknown
        case denied
        case authorized
    }

    private(set) var audioStatus: Status = .unknown
    private(set) var microphoneStatus: Status = .unknown
    
    var isAllGranted: Bool {
        return audioStatus == .authorized && microphoneStatus == .authorized
    }

    init() {
        #if ENABLE_TCC_SPI
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.updateStatus()
        }

        updateStatus()
        checkMicrophonePermission()
        #else
        audioStatus = .authorized
        microphoneStatus = .authorized
        #endif
    }

    func request() {
        requestAudioPermission()
        requestMicrophonePermission()
    }
    
    private func requestAudioPermission() {
        #if ENABLE_TCC_SPI
        logger.debug("Requesting audio permission")

        guard let request = Self.requestSPI else {
            logger.fault("Request SPI missing")
            return
        }

        request("kTCCServiceAudioCapture" as CFString, nil) { [weak self] granted in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.audioStatus = granted ? .authorized : .denied
            }
        }
        #endif
    }
    
    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.microphoneStatus = granted ? .authorized : .denied
            }
        }
    }

    private func updateStatus() {
        #if ENABLE_TCC_SPI
        logger.debug("Updating status")

        guard let preflight = Self.preflightSPI else {
            logger.fault("Preflight SPI missing")
            return
        }

        let result = preflight("kTCCServiceAudioCapture" as CFString, nil)
        
        if result == 1 {
            audioStatus = .denied
        } else if result == 0 {
            audioStatus = .authorized
        } else {
            audioStatus = .unknown
        }
        #endif
    }
    
    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .authorized
        case .denied, .restricted:
            microphoneStatus = .denied
        case .notDetermined:
            microphoneStatus = .unknown
        @unknown default:
            microphoneStatus = .unknown
        }
    }

    #if ENABLE_TCC_SPI
    private typealias PreflightFuncType = @convention(c) (CFString, CFDictionary?) -> Int
    private typealias RequestFuncType = @convention(c) (CFString, CFDictionary?, @escaping (Bool) -> Void) -> Void

    private static let apiHandle: UnsafeMutableRawPointer? = {
        let tccPath = "/System/Library/PrivateFrameworks/TCC.framework/Versions/A/TCC"

        guard let handle = dlopen(tccPath, RTLD_NOW) else {
            assertionFailure("dlopen failed")
            return nil
        }

        return handle
    }()

    private static let preflightSPI: PreflightFuncType? = {
        guard let apiHandle else { return nil }

        let fnName = "TCCAccessPreflight"

        guard let funcSym = dlsym(apiHandle, fnName) else {
            assertionFailure("Couldn't find symbol")
            return nil
        }

        let fn = unsafeBitCast(funcSym, to: PreflightFuncType.self)

        return fn
    }()

    private static let requestSPI: RequestFuncType? = {
        guard let apiHandle else { return nil }

        let fnName = "TCCAccessRequest"

        guard let funcSym = dlsym(apiHandle, fnName) else {
            assertionFailure("Couldn't find symbol")
            return nil
        }

        let fn = unsafeBitCast(funcSym, to: RequestFuncType.self)

        return fn
    }()
    #endif
}
