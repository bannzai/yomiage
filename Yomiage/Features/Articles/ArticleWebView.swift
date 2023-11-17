import SwiftUI
import Foundation
import WebKit

struct ArticleWebViewPage: View {
  let article: Article

  var body: some View {
let _ = Self._printChanges()
    if let url = URL(string: article.pageURL) {
      ArticleWebView(url: url)
        .navigationTitle(article.title ?? "Unknown title")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

typealias ArticleWebView = WebView
