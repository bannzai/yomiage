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
      let htmlToSSML = try await functions.htmlToSSML(url: url, html: html)
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
