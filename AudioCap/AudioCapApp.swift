import SwiftUI

let kAppSubsystem = "codes.rambo.AudioCap"

@main
struct AudioCapApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(width: 500, height: 500)
                .fixedSize()
        }
        .windowResizability(.contentSize)
    }
}
