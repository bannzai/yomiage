import SwiftUI

struct AddArticleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.articleDatastore) private var articleDatastore

  @StateObject private var loader = AddArticleHTMLLoader()
  @State private var text: String = ""
  @State private var error: Error?

  var body: some View {
    ZStack {
      if let url = loader.loadingURL {
        LoadHTMLWebView(url: url, loader: loader)
      }

      MediumSheetLayout(
        title: {
          Text("記事を追加")
            .font(.headline)
        },
        content: {
          VStack(spacing: 16) {
            VStack(spacing: 0) {
              TextField("https://", text: $text)
              VSpacer(10)
              Divider()
                .foregroundColor(.label)
            }

            Button {
              if let url = url {
                loader.load(url: url)
              }
            } label: {
              Text("追加する")
            }
            .buttonStyle(.primary)
            .disabled(url == nil || loader.loadingURL != nil)
          }
          .padding(.horizontal, 20)
        }
      )

      if loader.loadingURL != nil {
        HUD()
      }
    }
    .onReceive(loader.$loadedArticle) { article in
      if let article = article {
        Task { @MainActor in
          do {
            try await articleDatastore.create(article: article)
            dismiss()
          } catch {
            self.error = error
          }
        }
      }
    }
    .onReceive(loader.$localizedError, perform: { error in
      self.error = error
    })
    .errorAlert(error: $error)
  }

  private var url: URL? { .init(string: text) }
}


private struct AddArticleError: LocalizedError {
  let error: Error?

  var errorDescription: String? {
    "記事の登録に失敗しました"
  }
  var failureReason: String? {
    error?.localizedDescription
  }
  var recoverySuggestion: String?
  var helpAnchor: String?
}
