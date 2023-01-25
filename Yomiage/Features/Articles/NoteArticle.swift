import SwiftUI

struct NoteArticle: View {
  let article: Article
  let noteArticle: Article.Note?

  var body: some View {
    if let noteArticle = noteArticle {
      ZStack {
        ArticleRowLayout(
          article: article,
          thumbnailImage: {
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
          },
          title: {
            Text(noteArticle.title)
          },
          author: {
            Text(noteArticle.author)
          }
        )
        .padding()
      }
    }
  }
}

