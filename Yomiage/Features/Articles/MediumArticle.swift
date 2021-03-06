import SwiftUI

struct MediumArticle: View {
  @EnvironmentObject private var player: Player

  let article: Article
  let mediumArticle: Article.Medium?

  var body: some View {
    if let mediumArticle = mediumArticle {
      ZStack {
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
            if player.playingArticle == article {
              Button {
                analytics.logEvent("medium_article_stop_play", parameters: ["article_id": String(describing: article.id)])

                player.stop()
              } label: {
                Image(systemName: "stop.fill")
                  .frame(width: 14, height: 14)
                  .foregroundColor(.label)
                  .padding()
              }
            } else {
              AsyncButton {
                analytics.logEvent("medium_article_start_play", parameters: ["article_id": String(describing: article.id)])

                await player.start(article: article)
                player.configurePlayingCenter(title: mediumArticle.title)
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


