import FirebaseCrashlytics
import FirebaseAuth

let errorLogger = FirebaseCrashlytics.Crashlytics.crashlytics()

extension Crashlytics {
  func setup(user: FirebaseAuth.User) {
    setUserID(user.uid)
  }
}

