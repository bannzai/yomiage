import SwiftUI
import Kanna

@Observable final class AddArticleHTMLLoader {
  var isLoading: Bool = false
  var localizedError: AddArticleError?
  var loadedArticle: Article?

  @MainActor func load(url: URL) async {
    analytics.logEvent("load_html_body", parameters: ["url": url.absoluteString])

    do {
      isLoading = true
      defer {
        isLoading = false
      }

      let html = try await loadHTML(url: url)
      let htmlToSSML = try await functions.htmlToSSML(html: html)
      do {
        loadedArticle = try proceedReadArticle(html: html, loadingURL: url)
      } catch {
        errorLogger.record(error: error)
        throw error
      }
    } catch {
      self.localizedError = .init(error: error)
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

struct AddArticleError: LocalizedError, Equatable {
  static func == (lhs: AddArticleError, rhs: AddArticleError) -> Bool {
    lhs._domain == rhs._domain && lhs._code == rhs._code
  }
  
  let error: Error?

  var errorDescription: String? {
    "記事の登録に失敗しました"
  }
  var failureReason: String? {
    error?.localizedDescription
  }
  var recoverySuggestion: String?
  var helpAnchor: String?
}
