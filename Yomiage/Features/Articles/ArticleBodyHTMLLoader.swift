import SwiftUI
import Kanna

final class ArticleBodyHTMLLoader: ObservableObject {
  @Published private(set) var loadingArticle: Article?
  @Published var localizedError: Error?
  @Published private(set) var loadedBody: String?

  func load(article: Article) {
    loadingArticle = article
  }
}

extension ArticleBodyHTMLLoader: LoadHTMLLoader {
  func javaScript() -> String? {
    guard let article = loadingArticle else {
      return nil
    }

    switch article.typedKind {
    case .note:
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
    case .medium:
      return """
const bodyDocument = document.querySelector("article").querySelector("section");
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
    case nil:
      return nil
    }
  }
  
  func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
    defer {
      self.loadingArticle = nil
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
