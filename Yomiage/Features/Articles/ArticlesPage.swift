import SwiftUI

struct ArticlesPage: View {
  @Environment(\.articleDatastore) var articleDatastore
  @EnvironmentObject var player: Player

  @State private var addArticleSheetIsPresented = false
  @State private var playerSettingSheetIsPresented = false

  var body: some View {
    StreamView(stream: articleDatastore.articlesStream()) { articles in
      if articles.isEmpty {
        VStack(spacing: 0) {
          Text("記事を追加しましょう")
            .font(.system(.headline))
          VSpacer(20)
          Button {
            addArticleSheetIsPresented = true
          } label: {
            Text("追加")
          }
          .buttonStyle(.primary)
          .frame(width: 200)
          .navigationBarHidden(true)
        }
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
              // TODO:
              EmptyView()
            case nil:
              EmptyView()
            }
          }
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationBarHidden(false)
        .navigationTitle("記事一覧")
        .toolbar(content: {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              playerSettingSheetIsPresented = true
            } label: {
              Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundColor(Color(.label))
                .frame(width: 28, height: 28)
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              addArticleSheetIsPresented = true
            } label: {
              Image(systemName: "plus")
                .imageScale(.large)
                .foregroundColor(Color(.label))
                .frame(width: 28, height: 28)
            }
          }
        })
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
  }
}


struct NoteArticle: View {
  let article: Article
  let noteArticle: Article.Note?

  var body: some View {
    if let noteArticle = noteArticle {
      HStack {
        Group {
          if let eyeCatchImageURL = noteArticle.eyeCatchImageURL,
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
        .frame(width: 60, height: 60)
        .background(Color(.systemGray5))
        .cornerRadius(8)

        VStack(alignment: .leading, spacing: 10) {
          Text(noteArticle.title)
            .font(.system(.headline))
          Text(noteArticle.author)
            .font(.system(.caption))
        }
      }
      .padding()
    }
  }
}
