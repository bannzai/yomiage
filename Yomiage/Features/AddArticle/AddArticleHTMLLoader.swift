import SwiftUI
import Kanna

final class AddArticleHTMLLoader: ObservableObject {
  @Environment(\.articleDatastore) private var articleDatastore

  typealias Target = (url: URL, kind: Article.Kind)
  @Published private(set) var target: Target?
  @Published private(set) var localizedError: Error?
  @Published private(set) var loadedArticle: Article?

  func load(url: URL) {
    switch url.host {
    case "note.com":
      target = (url, .note)
    case "medium.com":
      target = (url, .medium)
    case _:
      localizedError = HostMismatchError()
    }
  }
}

extension AddArticleHTMLLoader: LoadHTMLLoader {
  func javaScript() -> String? {
"""
window.document.getElementsByTagName('html')[0].outerHTML;
"""
  }

  func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
    guard let target = target else {
      return
    }

    defer {
      self.target = nil
    }

    if let html = arguments.0 as? String {
      proceedRead(html: html, target: target)
    } else if let loadError = arguments.1 {
      localizedError = WebViewLoadHTMLError(error: loadError)
    } else {
      localizedError = WebViewLoadHTMLError(error: nil)
    }
  }

  private func proceedRead(html: String, target: Target) {
    do {
      let doc = try HTML(html: html, encoding: .utf8)
      switch target.kind {
      case .note:
        if let title = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/h1"#)?.text?.trimmed,
           let author = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/div[2]/div/div[1]/div/a"#)?.text?.trimmed {
          // NOTE: Actual HTML: #"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/figure/a/img"#
          // However, via Kanna, the last <a> tag is missing
          let eyeCatchImageURL = doc.at_xpath(#"//*[@id="__layout"]/div/div[1]/div[2]/main/div[1]/article/div[1]/div/div/figure/img"#)?["src"]
          loadedArticle = .init(
            kind: Article.Kind.note.rawValue,
            note: .init(
              title: title,
              pageURL: target.url.absoluteString,
              author: author,
              eyeCatchImageURL: eyeCatchImageURL,
              createdDate: .init()
            )
          )
        } else {
          throw "ページが読み込めませんでした。URLをご確認ください"
        }
      case .medium:
        fatalError()
      }
    } catch {
      localizedError = WebViewLoadHTMLError(error: error)
    }
  }

}

fileprivate struct HostMismatchError: LocalizedError {
  var errorDescription: String? {
    "対応していないURLです"
  }
  var failureReason: String? {
    "note.com,medium.comで記事が存在するURLを入力してください"
  }
  let helpAnchor: String? = nil
  let recoverySuggestion: String? = nil
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
