import SwiftUI

struct RootView: View {
    @Environment(\.auth) private var auth
    @StateObject var screenStateNotifier = ScreenStateNotifier()

    @State private var signInError: Error?

    var body: some View {
        NavigationView {
            if let signInError = signInError {
                UniversalErrorView(error: signInError, reload: signIn)
            } else {
                switch screenStateNotifier.state {
                case .waiting:
                    ProgressView()
                        .onAppear(perform: signIn)
                case .main:
                    ArticlesPage()
                }
            }
        }
        .onAppear(perform: screenStateNotifier.launch)
    }

    private func signIn() {
        Task { @MainActor in
            do {
                _ = try await auth.signIn()
            } catch {
                signInError = error
            }
        }
    }
}
