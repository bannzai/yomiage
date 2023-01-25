import SwiftUI

final class HTMLBodyDownloader: ObservableObject {
  @MainActor func callAsFunction(kind: Article.Kind, pageURL: URL) async throws -> String {
    switch kind {
    case .note:
      return try await loadNoteBody(url: pageURL)
    case .medium:
      return try await loadMediumBody(url: pageURL)
    }
  }
}
