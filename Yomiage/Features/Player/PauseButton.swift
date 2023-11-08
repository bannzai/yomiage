import SwiftUI

struct PauseButton: View {
  @EnvironmentObject var player: Player

  let article: Article

  var body: some View {
    Button {
      analytics.logEvent("article_pause_play", parameters: ["article_id": String(describing: article.id)])

      player.pause()
    } label: {
      Image(systemName: "pause.fill")
        .frame(width: 14, height: 14)
        .foregroundColor(.label)
        .padding()
    }
  }
}
