import SwiftUI

struct PlayButton: View {
  @EnvironmentObject var player: Player

  let article: Article

  var body: some View {
    AsyncButton {
      analytics.logEvent("article_start_play", parameters: ["article_id": String(describing: article.id)])

      if player.playingArticle == nil {
        player.play(article: article)
      } else {
        player.resume()
      }
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
    .errorAlert(error: $player.error)
  }
}
