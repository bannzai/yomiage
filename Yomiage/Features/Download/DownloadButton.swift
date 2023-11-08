import SwiftUI

struct DownloadButton: View {
  let article: Article
  @ObservedObject var synthesizer: Synthesizer

  @StateObject private var downloader = HTMLBodyDownloader()
  @State private var error: Error?
  @State private var isDownloading = false

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        isDownloading = true
        Task { @MainActor in
          do {
            let body = try await downloader(kind: kind, pageURL: pageURL)
            _ = try await synthesizer.writeToAudioFile(body: body, pageURL: pageURL)
          } catch {
            self.error = error
          }
          isDownloading = false
        }
      } label: {
        if isDownloading {
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
