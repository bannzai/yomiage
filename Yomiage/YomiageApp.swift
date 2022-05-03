import SwiftUI

@main
struct YomiageApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  init() {
    Player.DefaultValues.setup()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}
