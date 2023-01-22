import SwiftUI

final class HTMLBodyDownloader: ObservableObject {
  @Published var body: String?
  @Published var error: Error?

  func callAsFunction(kind: Article.Kind, pageURL: URL) {
    Task { @MainActor [self] in
      do {
        switch kind {
        case .note:
          body = try await loadNoteBody(url: pageURL)
        case .medium:
          body = try await loadMediumBody(url: pageURL)
        }
      } catch {
        self.error = error
      }
    }
  }
}
