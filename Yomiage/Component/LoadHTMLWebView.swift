import SwiftUI
import WebKit
import Combine

class AbstractLoadHTMLView: WKWebView, WKNavigationDelegate {
  let evaluatedJavaScript: (Result<String, WebViewLoadHTMLError>) -> Void

  init(url: URL, evaluatedJavaScript: @escaping (Result<String, WebViewLoadHTMLError>) -> Void) {
    self.evaluatedJavaScript = evaluatedJavaScript

    super.init(frame: .zero, configuration: .init())

    navigationDelegate = self
    load(.init(url: url))

    // LoadHTMLWebView should invisible, because LoadHTMLWebView is for getting HTML using the Browser's function
    frame = .zero
    layer.opacity = 0
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  var javaScript: String {
    fatalError("Must be implement on subclass")
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript(javaScript, completionHandler: { [weak self] value, error in
        if let body = value as? String {
          self?.evaluatedJavaScript(.success(body))
        } else {
          self?.evaluatedJavaScript(.failure(.init(error: error)))
        }
      })
  }
}

final class LoadHTMLWebView: AbstractLoadHTMLView {
  override var javaScript: String {
"""
window.document.getElementsByTagName('html')[0].outerHTML;
"""
  }
}

final class NoteArticleBodyLoadHTMLWebView: AbstractLoadHTMLView {
  override var javaScript: String {
"""
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
}

final class MediumArticleBodyLoadHTMLWebView: AbstractLoadHTMLView {
  override var javaScript: String {
"""
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
  }
}

struct WebViewLoadHTMLError: LocalizedError {
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
