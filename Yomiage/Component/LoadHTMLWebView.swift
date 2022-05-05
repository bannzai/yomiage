import SwiftUI
import WebKit
import Combine

protocol LoadHTMLLoader {
  func javaScript() -> String?
  func handlEevaluateJavaScript(arguments: (Any?, Error?))
}

struct LoadHTMLWebView<Loader: LoadHTMLLoader & ObservableObject>: UIViewRepresentable {
  let url: URL
  @ObservedObject var loader: Loader

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView(frame: .zero)
    webView.navigationDelegate = context.coordinator
    webView.load(.init(url: url))

    // LoadHTMLWebView should invisible, because LoadHTMLWebView is for getting HTML using the Browser's function
    webView.frame = .zero
    webView.layer.opacity = 0

    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    // None
  }

  func makeCoordinator() -> WebViewCoordinator<Loader> {
    WebViewCoordinator(loader: _loader)
  }
}

final class WebViewCoordinator<Loader: LoadHTMLLoader & ObservableObject>: NSObject, WKNavigationDelegate {
  @ObservedObject var loader: Loader
  init(loader: ObservedObject<Loader>) {
    _loader = loader
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if let javaScript = loader.javaScript() {
      webView.evaluateJavaScript(javaScript, completionHandler: { [weak self] value, error in
        self?.loader.handlEevaluateJavaScript(arguments: (value, error))
      })
    }
  }
}

class AbstractLoadHTMLView: WKWebView, WKNavigationDelegate {
  let publisher = PassthroughSubject<String, WebViewLoadHTMLError>()

  init(url: URL) {
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
    fatalError("Require implement to subclass")
  }
}

final class NoteArticleBodyLoadHTMLWebView: AbstractLoadHTMLView {
  private var javaScript: String {
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

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript(javaScript, completionHandler: { [weak self] value, error in
//        self?.publisher.send("")
//        self?.publisher.send(completion: .finished)
      })
    }
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
