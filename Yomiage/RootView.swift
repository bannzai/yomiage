import SwiftUI

struct RootView: View {
  @Environment(\.auth) private var auth

  @StateObject var screenStateNotifier = ScreenStateNotifier()
  @StateObject var player = Player()

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
            .environmentObject(player)
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
        _ = try await auth.signInOrCachedUser()
      } catch {
        signInError = error
      }
    }
  }
}
