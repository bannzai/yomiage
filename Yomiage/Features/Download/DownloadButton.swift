import SwiftUI

struct DownloadButton: View {
  let article: Article
  @StateObject var synthesizer = Synthesizer()

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        Task { @MainActor in
          downloadHTMLBody(kind: kind, pageURL: pageURL)
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
