import SwiftUI

@main
struct YomiageApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  init() {
    Player.DefaultValues.setup()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
    .onChange(of: scenePhase) { scenePhase in
      switch scenePhase {
      case .active:
        UIApplication.shared.beginReceivingRemoteControlEvents()
      case .background:
        return
      case .inactive:
        return
      @unknown default:
        return
      }
    }
  }
}
