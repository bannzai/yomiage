import SwiftUI

final class HTMLBodyDownloader: ObservableObject {
  @Published var isLoading = false

  func callAsFunction(kind: Article.Kind, pageURL: URL) async throws -> String {
    isLoading = true
    defer {
      isLoading = false
    }
    switch kind {
    case .note:
      return try await loadNoteBody(url: pageURL)
    case .medium:
      return try await loadMediumBody(url: pageURL)
    }
  }
}
