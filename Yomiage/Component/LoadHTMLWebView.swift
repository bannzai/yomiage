import SwiftUI
import WebKit

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

class WebView<Loader: LoadHTMLLoader & ObservableObject>: WKWebView, WKNavigationDelegate {
  let loader: Loader
  init(url: URL, loader: Loader) {
    self.loader = loader

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
    if let javaScript = loader.javaScript() {
      webView.evaluateJavaScript(javaScript, completionHandler: { [weak self] value, error in
        self?.loader.handlEevaluateJavaScript(arguments: (value, error))
      })
    }
  }

}
