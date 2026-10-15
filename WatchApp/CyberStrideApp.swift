import SwiftUI

@main
struct CyberStrideApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine = CyberStrideEngine()

    var body: some Scene {
        WindowGroup {
            CyberStrideWatchView(engine: engine)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase != .active {
                        engine.onWristDropped()
                    }
                }
        }
    }
}
