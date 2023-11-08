import SwiftUI

struct DownloadButton: View {
  let article: Article
  @ObservedObject var synthesizer: Synthesizer

  @State private var error: Error?
  @State private var isDownloading = false

  var body: some View {
    if let pageURL = URL(string: article.pageURL) {
      Button {
        isDownloading = true
        Task { @MainActor in
          do {
            let html = try await loadHTML(url: pageURL)
            let htmlToSSML = try await functions.htmlToSSML(url: pageURL, html: html)
            _ = try await synthesizer.writeToAudioFile(htmlToSSML: htmlToSSML, pageURL: pageURL)
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
