import SwiftUI
import Foundation
import WebKit

struct ArticleWebViewPage: View {
  let article: Article

  var body: some View {
    switch article.typedKind {
    case .note:
      if let note = article.note, let url = URL(string: article.pageURL) {
        ArticleWebView(url: url)
          .navigationTitle(note.title)
          .navigationBarTitleDisplayMode(.inline)
      }
    case .medium:
      if let medium = article.medium, let url = URL(string: article.pageURL) {
        ArticleWebView(url: url)
          .navigationTitle(medium.title)
          .navigationBarTitleDisplayMode(.inline)
      }
    case nil:
      EmptyView()
    }
  }
}

typealias ArticleWebView = WebView
