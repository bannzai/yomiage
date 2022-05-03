import SwiftUI
import Kanna

final class ArticleBodyHTMLLoader: ObservableObject {
  @Published private(set) var article: Article?
  @Published var localizedError: Error?
  @Published private(set) var loadedBody: String?

  func load(article: Article) {
    self.article = article
  }
}

extension ArticleBodyHTMLLoader: LoadHTMLLoader {
  func javascript() -> String? {
    guard article != nil else {
      return ""
    }

    return """
const bodyDocument = document.getElementsByClassName('note-common-styles__textnote-body')[0];
const body = Array.from(bodyDocument.children).reduce((previousValue, element) => {
  if (['h1', 'h2', 'h3', 'h4'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n' + '\\n';
  } else if (['p', 'ul'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n';
  } else {
    return previousValue + element.textContent;
  }
},'');
body;
"""
  }
  
  func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
    defer {
      self.article = nil
    }

    print("arguments: \(arguments)")
    if let html = arguments.0 as? String {
      loadedBody = html
    } else if let loadError = arguments.1 {
      localizedError = WebViewLoadHTMLError(error: loadError)
    } else {
      localizedError = WebViewLoadHTMLError(error: nil)
    }
  }
}

fileprivate struct WebViewLoadHTMLError: LocalizedError {
  let error: Error?

  var errorDescription: String? {
    "読み込みに失敗しました"
  }
  var failureReason: String? {
    (error as? LocalizedError)?.failureReason ?? "通信環境をお確かめの上再度実行してください"
  }
  let helpAnchor: String? = nil
  let recoverySuggestion: String? = nil
}
