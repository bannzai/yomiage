import SwiftUI
import Kanna

final class AddArticleHTMLLoader: ObservableObject {
  @Environment(\.articleDatastore) private var articleDatastore

  @Published private(set) var isLoading: Bool = false
  @Published private(set) var localizedError: LocalizedError?
  @Published private(set) var loadedArticle: Article?

  @MainActor func load(url: URL) async {
    analytics.logEvent("load_html_body", parameters: ["url": url.absoluteString])

    do {
      isLoading = true
      defer {
        isLoading = false
      }

      let html = try await loadHTML(url: url)
      do {
        loadedArticle = try proceedReadArticle(html: html, loadingURL: url)
      } catch {
        errorLogger.record(error: error)
        throw error
      }
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
    if let title = doc.at_xpath("//h1[contains(@class, 'o-noteContentHeader__title')]")?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
       let author = doc.at_xpath("//div[contains(@class, 'o-noteContentHeader__name')]/a")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
      let eyeCatchImageURL: String? = doc.at_xpath("//img[contains(@class, 'o-noteEyecatch__image')]")?["src"]?.trimmingCharacters(in: .whitespacesAndNewlines)

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
    if let title = doc.at_xpath("//h1[contains(@class, 'pw-post-title')]")?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
       let author = doc.at_xpath("//div[contains(@class, 'pw-author')]/div[1]/div/div/a")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
      let eyeCatchImageURL: String? = doc.at_xpath("//figure[contains(@class, 'paragraph-image')]/div/div/img")?["src"]?.trimmingCharacters(in: .whitespacesAndNewlines)

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
