import SwiftUI

struct PlayButton: View {
  let article: Article
  @ObservedObject var player: Player

  var body: some View {
    AsyncButton {
      analytics.logEvent("article_start_play", parameters: ["article_id": String(describing: article.id), "kind": article.kind])

      await player.play(article: article)
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
