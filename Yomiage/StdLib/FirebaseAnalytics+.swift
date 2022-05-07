import FirebaseAnalytics

let analytics: FirebaseAnalytics.Analytics.Type = FirebaseAnalytics.Analytics.self

extension FirebaseAnalytics.Analytics {
  static func logEvent(_ name: String) {
    logEvent(name, parameters: nil)
  }
}
