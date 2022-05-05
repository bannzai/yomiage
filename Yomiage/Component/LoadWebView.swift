import SwiftUI
import WebKit
import Combine

private final class LoadWebView: WKWebView, WKNavigationDelegate {
  let javaScript: String
  let evaluatedJavaScript: (Result<String, WebViewLoadHTMLError>) -> Void

  init(
    url: URL,
    javaScript: String,
    evaluatedJavaScript: @escaping (Result<String, WebViewLoadHTMLError>) -> Void
  ) {
    self.javaScript = javaScript
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

private struct Loader {
  let webView: LoadWebView
  init(
    url: URL,
    javaScript: String,
    evaluatedJavaScript: @escaping (Result<String, WebViewLoadHTMLError>) -> Void
  ) {
    webView = .init(url: url, javaScript: javaScript, evaluatedJavaScript: evaluatedJavaScript)
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

private func load(url: URL, javaScript: String) async throws -> String {
  try await withCheckedThrowingContinuation { continuation in
    // Keep Reference
    _ = Loader(
      url: url,
      javaScript: javaScript) { result in
        do {
          continuation.resume(returning: try result.get())
        } catch {
          continuation.resume(throwing: error)
        }
      }
  }
}

func loadHTML(url: URL) async throws -> String {
  let javaScript =
"""
window.document.getElementsByTagName('html')[0].outerHTML;
"""

  return try await load(
    url: url,
    javaScript: javaScript
  )
}

func loadNoteBody(url: URL) async throws -> String {
  let javaScript = """
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

  return try await load(
    url: url,
    javaScript: javaScript
  )
}

var mediumBodyJavaScript: String {
  func loadMediumBody(url: URL) async throws -> String {
    let javaScript = """
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

    return try await load(
      url: url,
      javaScript: javaScript
    )
  }
