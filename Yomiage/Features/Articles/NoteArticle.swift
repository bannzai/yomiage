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
            if player.playingArticle == article {
              Button {
                analytics.logEvent("note_article_stop_play", parameters: ["article_id": String(describing: article.id)])

                player.stop()
              } label: {
                Image(systemName: "stop.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
                  .padding()
              }
            } else {
              AsyncButton {
                analytics.logEvent("note_article_start_play", parameters: ["article_id": String(describing: article.id)])
                
                await player.play(article: article)
                player.configurePlayingCenter(title: noteArticle.title)
              } label: {

                Image(systemName: "play.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
                  .padding()
              } progress: {
                ProgressView()
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
        .errorAlert(error: $player.error)
      }
    }
  }
}

