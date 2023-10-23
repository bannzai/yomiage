import SwiftUI

@main
struct YomiageApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
  var loader = AddArticleHTMLLoader()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(loader)
    }
  }
}
