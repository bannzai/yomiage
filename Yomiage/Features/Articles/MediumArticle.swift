import SwiftUI

struct MediumArticle: View {
  @EnvironmentObject private var player: Player
  @StateObject private var loader = ArticleBodyHTMLLoader()

  let article: Article
  let mediumArticle: Article.Medium?

  var body: some View {
    if let mediumArticle = mediumArticle {
      ZStack {
        if let article = loader.loadingArticle, let url = URL(string: article.pageURL) {
          LoadHTMLWebView(url: url, loader: loader)
        }

        ArticleRowLayout(
          thumbnailImage: {
            Group {
              if let eyeCatchImageURL = mediumArticle.eyeCatchImageURL,
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
            Text(mediumArticle.title)
          },
          author: {
            Text(mediumArticle.author)
          },
          playButton: {
            if loader.loadingArticle != nil {
              ProgressView()
                .frame(width: 14, height: 14)
                .foregroundColor(.label)
                .padding()
            } else if player.playingArticle == article {
              Button {
                player.stop()
              } label: {
                Image(systemName: "stop.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
                  .padding()
              }
            } else {
              Button {
                loader.load(article: article)
              } label: {
                Image(systemName: "play.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
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
                .foregroundColor(.label)
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

          player.speak(article: article, title: mediumArticle.title, text: body)
        }
      }
    }
  }
}


