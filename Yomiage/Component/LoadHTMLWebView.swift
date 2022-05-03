import SwiftUI
import WebKit

protocol LoadHTMLLoader {
  func javascript() -> String?
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
    if let javascript = loader.javascript() {
      webView.evaluateJavaScript(javascript, completionHandler: { [weak self] value, error in
        self?.loader.handlEevaluateJavaScript(arguments: (value, error))
      })
    }
  }
}
