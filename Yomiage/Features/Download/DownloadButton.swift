import SwiftUI

struct DownloadButton: View {
  let article: Article
  @ObservedObject var synthesizer: Synthesizer

  @StateObject private var downloader = HTMLBodyDownloader()
  @State private var error: Error?

  var body: some View {
    if let pageURL = URL(string: article.pageURL), let kind = article.typedKind {
      Button {
        Task { @MainActor in
          do {
            let body = try await downloader(kind: kind, pageURL: pageURL)
            synthesizer.writeToAudioFile(body: body, pageURL: pageURL)
          } catch {
            self.error = error
          }
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
      .errorAlert(error: $synthesizer.error)
    }
  }

  private var isLoading: Bool {
    downloader.isLoading || synthesizer.isLoading
  }
}
