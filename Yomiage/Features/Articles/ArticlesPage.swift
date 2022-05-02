import SwiftUI

struct ArticlesPage: View {
    @Environment(\.articleDatastore) var articleDatastore

    var body: some View {
        StreamView(stream: articleDatastore.articlesStream()) { articles in
            List {
                ForEach(articles) { article in
                    switch article.typedKind {
                    case .note:
                        NoteArticle(article: article, noteArticle: article.note)
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
        } errorContent: { error, reload in
            UniversalErrorView(error: error, reload: reload)
        } loading: {
            ProgressView()
        }
    }
}


struct NoteArticle: View {
    let article: Article
    let noteArticle: Article.Note?

    var body: some View {
        if let noteArticle = noteArticle {
            HStack {
                if let eyeCatchImageURL = noteArticle.eyeCatchImageURL,
                   let url = URL(string: eyeCatchImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 60, height: 60)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 60, height: 60)
                    }
                }

                VStack {
                    Text(noteArticle.title)
                        .font(.system(.headline))
                    Text(noteArticle.author)
                        .font(.system(.caption))
                }
            }
        }
    }
}
