import SwiftUI
import Kanna

final class AddArticleHTMLLoader: ObservableObject {
  @Environment(\.articleDatastore) private var articleDatastore

  @Published private(set) var loadingURL: URL?
  @Published private(set) var localizedError: Error?
  @Published private(set) var loadedArticle: Article?

  func load(url: URL) {
    loadingURL = url
  }
}

extension AddArticleHTMLLoader: LoadHTMLLoader {
  func javaScript() -> String? {
"""
window.document.getElementsByTagName('html')[0].outerHTML;
"""
  }

  func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
    guard let loadingURL = loadingURL else {
      return
    }

    defer {
      self.loadingURL = nil
    }

    if let html = arguments.0 as? String {
      do {
        loadedArticle = try proceedReadArticle(html: html, loadingURL: loadingURL)
      } catch {
        localizedError = WebViewLoadHTMLError(error: error)
      }
    } else if let loadError = arguments.1 {
      localizedError = WebViewLoadHTMLError(error: loadError)
    } else {
      localizedError = WebViewLoadHTMLError(error: nil)
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

fileprivate struct WebViewLoadHTMLError: LocalizedError {
  let error: Error?

  var errorDescription: String? {
    "読み込みに失敗しました"
  }
  var failureReason: String? {
    (error as? LocalizedError)?.failureReason ?? "URLと通信環境をお確かめの上、再度実行をしてください"
  }
  let helpAnchor: String? = nil
  let recoverySuggestion: String? = nil
}
