import SwiftUI

struct DownloadButton: View {
  let article: Article

  @StateObject private var synthesizer = Synthesizer()
  @State private var error: Error?

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        Task { @MainActor in
          do {
            try await downloadHTMLBody(kind: kind, pageURL: pageURL)
          } catch {

          }
        }
      } label: {
        <#code#>
      }
    }
  }
}

func downloadHTMLBody(kind: Article.Kind, pageURL: URL) async throws -> String {
  switch kind {
  case .note:
    return try await loadNoteBody(url: pageURL)
  case .medium:
    return try await loadMediumBody(url: pageURL)
  }
}
