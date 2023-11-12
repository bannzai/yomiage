import SwiftUI
import WebKit
import Combine
import Kanna

@MainActor func loadHTML(url: URL) async throws -> Kanna.HTMLDocument {
  let javaScript =
"""
window.document.getElementsByTagName('html')[0].outerHTML;
"""

  let htmlString = try await load(
    url: url,
    javaScript: javaScript
  )
  return try HTML(html: htmlString, encoding: .utf8)
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

private final class LoadWebView: WKWebView, WKNavigationDelegate {
  var javaScript: String!
  var evaluatedJavaScript: ((Result<String, WebViewLoadHTMLError>) -> Void)!

  init() {
    super.init(frame: .zero, configuration: .init())
    navigationDelegate = self

    // LoadHTMLWebView should invisible, because LoadHTMLWebView is for getting HTML using the Browser's function
    layer.opacity = 0
    frame = .zero
  }

  @MainActor func load(
    url: URL,
    javaScript: String,
    evaluatedJavaScript: @escaping (Result<String, WebViewLoadHTMLError>) -> Void
  ) {
    self.javaScript = javaScript
    self.evaluatedJavaScript = evaluatedJavaScript

    load(.init(url: url))
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

@MainActor private func load(url: URL, javaScript: String, evalute: @escaping (Result<String, WebViewLoadHTMLError>) -> Void) {
  // HACK: Keep reference to end eval javaScript task via `load(url:javaScript) async throws -> String`
  var webView: LoadWebView? = LoadWebView()
  webView?.load(
    url: url,
    javaScript: javaScript,
    evaluatedJavaScript: { result in
      evalute(result)

      // Release reference after eval
      webView = nil
    }
  )
}

// NOTE: WKWebView should instantiate and call WKWebView#load on main thread
@MainActor private func load(url: URL, javaScript: String) async throws -> String {
  try await withCheckedThrowingContinuation { continuation in
    load(
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
