import SwiftUI
import FirebaseAuth

final class ScreenStateNotifier: ObservableObject {
  @Published var state: State = .waiting

  deinit {
    authStreamTask?.cancel()
  }

  private var authStreamTask: Task<Void, Never>?
  func launch() {
    authStreamTask?.cancel()
    authStreamTask = Task { @MainActor in
      for await user in Auth.shared.stateDidChange() {
        if let user = user {
          state = .main(user: user)
        } else {
          state = .waiting
        }
      }
    }
  }
}

extension ScreenStateNotifier {
  enum State {
    case waiting
    case main(user: FirebaseAuth.User)
  }
}
