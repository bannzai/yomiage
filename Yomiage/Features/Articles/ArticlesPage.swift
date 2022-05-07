import SwiftUI

struct ArticlesPage: View {
  @Environment(\.articleDatastore) var articleDatastore
  @EnvironmentObject var player: Player

  @State private var addArticleSheetIsPresented = false
  @State private var playerSettingSheetIsPresented = false
  @State private var error: Error?

  var body: some View {
    StreamView(stream: articleDatastore.articlesStream()) { articles in
      if articles.isEmpty {
        VStack(spacing: 0) {
          Text("記事を追加しましょう")
            .font(.system(.headline))
          VSpacer(20)
          Button {
            analytics.logEvent("add_article_button_pressed", parameters: nil)
            addArticleSheetIsPresented = true
          } label: {
            Text("追加")
          }
          .buttonStyle(.primary)
          .frame(width: 200)
        }
        .navigationBarHidden(true)
      } else {
        List {
          ForEach(articles) { article in
            switch article.typedKind {
            case .note:
              VStack(alignment: .leading, spacing: 0) {
                NoteArticle(article: article, noteArticle: article.note)
                Divider()
              }
            case .medium:
              VStack(alignment: .leading, spacing: 0) {
                MediumArticle(article: article, mediumArticle: article.medium)
                Divider()
              }
            case nil:
              EmptyView()
            }
          }
          .onDelete(perform: { indexSet in
            indexSet.forEach { index in
              Task { @MainActor in
                do {
                  try await articleDatastore.delete(article: articles[index])
                } catch {
                  self.error = error
                }
              }
            }
          })
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationBarHidden(false)
        .navigationTitle("一覧")
        .toolbar(content: {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              analytics.logEvent("player_setting_present_toolbar_button")

              playerSettingSheetIsPresented = true
            } label: {
              Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundColor(.label)
                .frame(width: 28, height: 28)
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              analytics.logEvent("add_article_present_toolbar_button")

              addArticleSheetIsPresented = true
            } label: {
              Image(systemName: "plus")
                .imageScale(.large)
                .foregroundColor(.label)
                .frame(width: 28, height: 28)
            }
          }
        })
        .onAppear {
          articles.forEach { article in
            player.allArticle.insert(article)
          }
        }
      }
    } errorContent: { error, reload in
      UniversalErrorView(error: error, reload: reload)
    } loading: {
      ProgressView()
    }
    .sheet(isPresented: $playerSettingSheetIsPresented, detents: [.medium()]) {
      PlayerSettingSheet()
        .environmentObject(player)
    }
    .sheet(isPresented: $addArticleSheetIsPresented, detents: [.medium()]) {
      AddArticleSheet()
    }
    .errorAlert(error: $error)
  }
}
