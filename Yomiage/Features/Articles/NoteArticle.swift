import SwiftUI

struct NoteArticle: View {
  @EnvironmentObject private var player: Player
  @StateObject private var loader = ArticleBodyHTMLLoader()

  let article: Article
  let noteArticle: Article.Note?

  var body: some View {
    if let noteArticle = noteArticle {
      ZStack {
        if let article = loader.loadingArticle, let url = URL(string: article.pageURL) {
          LoadHTMLWebView(url: url, loader: loader)
        }

        ArticleRowLayout(
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
          },
          playButton: {
            if loader.loadingArticle != nil {
              ProgressView()
                .frame(width: 14, height: 14)
                .foregroundColor(.black)
                .padding()
            } else if player.playingArticle == article {
              Button {
                player.stop()
              } label: {
                Image(systemName: "stop.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.black)
                  .padding()
              }
            } else {
              Button {
                loader.load(article: article)
              } label: {
                Image(systemName: "play.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.black)
                  .padding()
              }
            }
          },
          webViewButton: {
            NavigationLink {
              ArticleWebViewPage(article: article)
            } label: {
              Image(systemName: "safari")
                .frame(width: 14, height: 14)
                .foregroundColor(.black)
                .padding()
            }
          }
        )
        .padding()
        .errorAlert(error: $loader.localizedError)
        .onReceive(loader.$loadedBody) { body in
          guard let body = body else {
            return
          }

          player.speak(article: article, title: noteArticle.title, text: body)
        }
      }
    }
  }
}

