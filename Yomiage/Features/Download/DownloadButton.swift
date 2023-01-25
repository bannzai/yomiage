import SwiftUI

struct DownloadButton: View {
  let article: Article
  // TODO:
  @ObservedObject var synthesizer: Synthesizer

  @StateObject private var downloader = HTMLBodyDownloader()
  @State private var isLoading = false
  @State private var error: Error?

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        isLoading = true
        Task { @MainActor in
          do {
            let body = try await downloader(kind: kind, pageURL: pageURL)
            let audioFile = try await synthesizer.writeToAudioFile(body: body, pageURL: pageURL)
          } catch {
            self.error = error
          }
          isLoading = false
        }
      } label: {
        if isLoading {
          ProgressView()
            .padding()
        } else {
          Image(systemName: "arrow.down.circle")
            .padding()
        }
      }
      .errorAlert(error: $error)
    }
  }
}
