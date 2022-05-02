import UIKit
import Firebase

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    setupFirebase()
    return true
  }
}

// MARK: - Private
private extension AppDelegate {
  func setupFirebase() {
    let firebaseFileName: String
#if DEBUG
    firebaseFileName = "GoogleService-Info-dev"
#else
    firebaseFileName = "GoogleService-Info-prod"
#endif

    let path = Bundle.main.path(forResource: firebaseFileName, ofType: "plist")!
    let options = FirebaseOptions(contentsOfFile: path)!

    FirebaseApp.configure(options: options)
  }

}
