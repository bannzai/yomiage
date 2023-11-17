import Async
import SwiftUI

struct ArticlesPage: View {
  @Async<StreamData<Article>> var async
  @Environment(\.articleDatastore) var articleDatastore
  @EnvironmentObject var player: Player
  @State var error: Error?

  var body: some View {

    Group {
      switch async(articleDatastore.articlesStream()).state {
      case .success(let data):
        let articles = data.all
        ArticlesBody(articles: articles)
          .onAppear {
            player.allArticle = articles
          }
      case .failure(let error):
        UniversalErrorView(error: error, reload: async.resetState)
      case .loading:
        ProgressView()
      }
    }
    .errorAlert(error: $error)
  }
}

struct ArticlesBody: View {
  @Environment(\.articleDatastore) var articleDatastore
  @EnvironmentObject var player: Player
  @StateObject private var synthesizer = Synthesizer()

  @State private var addArticleSheetIsPresented = false
  @State private var playerSettingSheetIsPresented = false
  @State private var error: Error?

  let articles: [Article]

  var body: some View {
    Group {
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
        ZStack(alignment: .bottom) {
          List {
            ForEach(articles) { article in
              ZStack {
                ArticleRowLayout(
                  article: article,
                  thumbnailImage: {
                    Group {
                      if let eyeCatchImageURL = article.eyeCatchImageURL,
                         let url = URL(string: eyeCatchImageURL) {
                        AsyncImage(url: url) { image in
                          image
                            .resizable()
                            .scaledToFill()
                        } placeholder: {
                          ProgressView()
                        }
                      } else {
                        Image(systemName: "photo")
                      }
                    }
                  },
                  title: {
                    Text(article.title ?? "Unknown title")
                  },
                  author: {
                    Text(article.author ?? "Unknown author")
                  }
                )
                .padding()
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

          if let playingArticle = player.playingArticle {
            PlayerBar(article: playingArticle)
          }
        }
        .navigationBarHidden(false)
        .navigationTitle("一覧")
        .toolbar(content: {
          ToolbarItem(placement: .navigationBarLeading) {
            NavigationLinkButton {
              AppOtherSettingPage()
            } label: {
              Image(systemName: "info.circle")
                .foregroundColor(.label)
            } tapped: {
              analytics.logEvent("app_other_menu_button_pressed")
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              analytics.logEvent("player_setting_present_toolbar_button")

              playerSettingSheetIsPresented = true
            } label: {
              ZStack(alignment: .bottomTrailing) {
                Image(systemName: "speaker.fill")
                  .font(.title2)
                  .foregroundColor(.label)

                Image(systemName: "gearshape")
                  .font(.caption2)
                  .foregroundColor(Color(.systemGray))
              }
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              analytics.logEvent("add_article_present_toolbar_button")

              addArticleSheetIsPresented = true
            } label: {
              Image(systemName: "plus")
                .foregroundColor(.label)
            }
          }
        })
      }
    }
    .sheet(isPresented: $addArticleSheetIsPresented, detents: [.medium()]) {
      AddArticleSheet(synthesizer: synthesizer)
    }
    .sheet(isPresented: $playerSettingSheetIsPresented, detents: [.medium()]) {
      PlayerSettingSheet()
        .environmentObject(player)
    }
    .errorAlert(error: $error)
  }
}
