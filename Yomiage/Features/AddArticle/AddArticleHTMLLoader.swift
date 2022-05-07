import SwiftUI
import Kanna

final class AddArticleHTMLLoader: ObservableObject {
  @Environment(\.articleDatastore) private var articleDatastore

  @Published private(set) var isLoading: Bool = false
  @Published private(set) var localizedError: LocalizedError?
  @Published private(set) var loadedArticle: Article?

  func load(url: URL) async {
    do {
      isLoading = true
      defer {
        isLoading = false
      }
      let html = try await loadHTML(url: url)
      loadedArticle = try proceedReadArticle(html: html, loadingURL: url)
    } catch {
      if let localizedError = error as? LocalizedError {
        self.localizedError = localizedError
      } else {
        self.localizedError = WebViewLoadHTMLError(error: error)
      }
    }
  }

  private func proceedReadArticle(html: String, loadingURL: URL) throws -> Article {
    let doc = try HTML(html: html, encoding: .utf8)

    // note.com
    if let title = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/h1"#)?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
       let author = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/div[2]/div/div[1]/div/a"#)?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
      let eyeCatchImageURL: String? = {
        if let first = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/figure/a/img"#)?["src"]?.trimmingCharacters(in: .whitespacesAndNewlines) {
          return first
        }

        // NOTE: Actual HTML: #"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/figure/a/img"#
        // However, via Kanna, the last <a> tag is missing
        return doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/figure/img"#)?["src"]?.trimmingCharacters(in: .whitespacesAndNewlines)
      }()

      return .init(
        kind: Article.Kind.note.rawValue,
        pageURL: loadingURL.absoluteString,
        note: .init(
          title: title,
          author: author,
          eyeCatchImageURL: eyeCatchImageURL,
          createdDate: .init()
        ),
        createdDate: .init()
      )
    }

    // medium.com
    if let title = doc.at_xpath(#"/html/body/div/div/div[3]/div/div/main/div/div[3]/div[1]/div/article/div/div[2]/section/div/div[2]/div[1]/h1"#)?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
       let author = doc.at_xpath(#"//*[@id="root"]/div/div[3]/div/div/main/div/div[3]/div[1]/div/article/div/div[2]/header/div[1]/div[1]/div[2]/div[1]/div/div[1]/div/a"#)?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
      let eyeCatchImageURL: String? = doc.at_xpath(#"//*[@id="root"]/div/div[3]/div/div/main/div/div[3]/div[1]/div/article/div/div[2]/section/div/div[2]/figure[1]/div/div/img"#)?["src"]?.trimmingCharacters(in: .whitespacesAndNewlines)

      return .init(
        kind: Article.Kind.medium.rawValue,
        pageURL: loadingURL.absoluteString,
        medium: .init(
          title: title,
          author: author,
          eyeCatchImageURL: eyeCatchImageURL,
          createdDate: .init()
        ),
        createdDate: .init()
      )
    }

    // No match
    throw "ページが読み込めませんでした。URLをご確認ください"
  }
}
