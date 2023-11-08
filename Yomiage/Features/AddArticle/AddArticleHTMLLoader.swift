import SwiftUI
import Kanna
import FirebaseFunctions

@Observable final class AddArticleHTMLLoader {
  @MainActor func load(url: URL) async throws -> Functions.HTMLToSSML {
    analytics.logEvent("load_html_body", parameters: ["url": url.absoluteString])

    let html = try await loadHTML(url: url)
    return (article, try await functions.htmlToSSML(url: url, html: html))
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
