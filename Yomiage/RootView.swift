import SwiftUI

struct RootView: View {
  @StateObject var screenStateNotifier = ScreenStateNotifier()

  @State private var signInError: Error?

  var body: some View {
    NavigationView {
      if let signInError = signInError {
        UniversalErrorView(error: signInError, reload: logIn)
      } else {
        switch screenStateNotifier.state {
        case .waiting:
          ProgressView()
            .onAppear(perform: logIn)
        case .main:
          ArticlesPage()
            .onAppear(perform: player.setupRemoteTransportControls)
        }
      }
    }
    .onAppear(perform: screenStateNotifier.launch)
    .onReceive(screenStateNotifier.$state) { state in
      if case let .main(user) = state {
        UserDatabase.shared.setUserID(user.uid)
      }
    }
  }

  private func logIn() {
    Task { @MainActor in
      do {
        let user = try await Auth.shared.signInOrCachedUser()
        errorLogger.setup(user: user)
      } catch {
        signInError = error
      }
    }
  }
}
