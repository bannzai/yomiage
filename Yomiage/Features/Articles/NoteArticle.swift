import SwiftUI

struct NoteArticle: View {
  @EnvironmentObject private var player: Player

  let article: Article
  let noteArticle: Article.Note?

  var body: some View {
    if let noteArticle = noteArticle {
      ZStack {
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
            if player.loadingArticle == article {
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
                player.load(article: article)
              } label: {
                Image(systemName: "play.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
                  .padding()
              }
            }
          },
          webViewButton: {
            NavigationLinkButton {
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
        .errorAlert(error: $player.localizedError)
        .onReceive(player.loadedBody) { body in
          guard player.loadingArticle == article else {
            return
          }
          player.speak(article: article, title: noteArticle.title, text: body)
        }
      }
    }
  }
}

