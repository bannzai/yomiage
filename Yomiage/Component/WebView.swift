import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  let url: URL

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView(frame: .zero)
    webView.load(.init(url: url))
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}
}
