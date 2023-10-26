import SwiftUI

struct AddArticleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.articleDatastore) private var articleDatastore

  @Environment(AddArticleHTMLLoader.self) var loader
  @State private var text: String = ""

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
                await loader.load(url: url)
                dismiss()
              }
            } label: {
              Text("追加する")
            } progress: {
              ProgressView()
            }
            .buttonStyle(.primary)
            .disabled(url == nil)

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
