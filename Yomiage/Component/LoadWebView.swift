import SwiftUI
import WebKit
import Combine

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

private func load(url: URL, javaScript: String, evaluted: @escaping (Result<String, WebViewLoadHTMLError>) -> Void) {
  // HACK: Keep reference to end eval javaScript task via `load(url:javaScript) async throws -> String`
  var webView: LoadWebView? = LoadWebView()
  webView?.load(
    url: url,
    javaScript: javaScript,
    evaluatedJavaScript: { result in
      evaluted(result)

      // Release reference after eval
      webView = nil
    }
  )
}

private func load(url: URL, javaScript: String) async throws -> String {
  try await withCheckedThrowingContinuation { continuation in
    Task { @MainActor in
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
