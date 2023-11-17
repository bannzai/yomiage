import SwiftUI
import FirebaseFirestore

struct AddArticleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.articleDatastore) private var articleDatastore

  @State private var text: String = ""
  @State private var error: Error?

  var body: some View {
    ZStack {
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

            AsyncButton {
              analytics.logEvent("add_article_button_on_sheet", parameters: ["url": String(describing: url?.absoluteString)])

              if let url = url {
                do {
                  let html = try await loadHTML(url: url)
                  let htmlToSSML = try await functions.htmlToSSML(url: url, html: html)

                  let article = htmlToSSML.article
                  try await articleDatastore.create(
                    article: .init(
                      pageURL: article.pageURL,
                      title: article.title,
                      author: article.author,
                      eyeCatchImageURL: article.eyeCatchImageURL,
                      createdDate: Timestamp(date: .now)
                    )
                  )
                  dismiss()
                } catch {
                  self.error = error
                }
              }
            } label: {
              Text("追加する")
            } progress: {
              ProgressView()
            }
            .buttonStyle(.primary)
            .disabled(url == nil)
            .errorAlert(error: $error)

            Text("※ 現在はnote.com,medium.comに対応しています")
              .font(.system(.caption2))
              .foregroundColor(Color(.lightGray))
          }
          .padding(.horizontal, 20)
        }
      )
    }
  }

  private var url: URL? { .init(string: text) }
}
