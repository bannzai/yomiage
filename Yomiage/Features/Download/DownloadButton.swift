import SwiftUI

struct DownloadButton: View {
  let article: Article
  @Binding private var isDownloading: Bool

  @StateObject private var downloader = HTMLBodyDownloader()
  @StateObject private var synthesizer = Synthesizer()
  @State private var error: Error?

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        isDownloading = true
        Task { @MainActor in
          do {
            let body = try await downloader(kind: kind, pageURL: pageURL)
            let audioFile = try await synthesizer.writeToAudioFile(body: body, pageURL: pageURL)
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
