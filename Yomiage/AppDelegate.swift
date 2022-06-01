import UIKit
import Firebase
import AVFAudio

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Setup Library
    setupFirebase()
    setupAudio()

    // Setup Appearance
    UINavigationBar.setupAppearance()
    UISlider.setupAppearance()

    return true
  }
}

// MARK: - Private
private extension AppDelegate {
  func setupFirebase() {
    FirebaseApp.configure()
  }

  func setupAudio() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
      try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print(error)
    }
  }
}
