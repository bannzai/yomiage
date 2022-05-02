import SwiftUI

struct ArticlesPage: View {
  @Environment(\.articleDatastore) var articleDatastore
  @State private var addArticleSheetIsPresented = false

  var body: some View {
    StreamView(stream: articleDatastore.articlesStream()) { articles in
      if articles.isEmpty {
        VStack(spacing: 0) {
          Text("記事を追加しましょう")
            .font(.system(.subheadline))
          Spacer()
            .frame(height: 20)
          Button {
            addArticleSheetIsPresented = true
          } label: {
            Text("追加")
          }
          .buttonStyle(.bordered)
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
      }
    } errorContent: { error, reload in
      UniversalErrorView(error: error, reload: reload)
    } loading: {
      ProgressView()
    }
    .toolbar(content: {
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
            } placeholder: {
              ProgressView()
            }
          } else {
            Rectangle()
              .background(Color.gray)
          }
        }
        .frame(width: 60, height: 60)
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
