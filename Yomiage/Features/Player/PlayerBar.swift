import SwiftUI

struct PlayerBar: View {
  @EnvironmentObject var player: Player

  let article: Article

  var body: some View {
    VStack {
      if let title = title {
        Text(title)
          .font(.subheadline.weight(.medium))
      }

      HStack {
        Button {
          analytics.logEvent("player_bar_play_button_pressed", parameters: ["article_id": String(describing: article.id)])

          player.stop()
        } label: {
          Image(systemName: "backward.frame.fill")
            .font(.body.weight(.heavy))
            .foregroundColor(.label)
            .padding()
        }
        Spacer()

        Button {
          analytics.logEvent("player_bar_play_button_pressed", parameters: ["article_id": String(describing: article.id)])

          player.stop()
        } label: {
          Image(systemName: "stop.fill")
            .font(.body.weight(.heavy))
            .foregroundColor(.label)
            .padding()
        }
        Spacer()

        Button {
          analytics.logEvent("player_bar_play_button_pressed", parameters: ["article_id": String(describing: article.id)])

          player.stop()
        } label: {
          Image(systemName: "forward.frame.fill")
            .font(.body.weight(.heavy))
            .foregroundColor(.label)
            .padding()
        }
      }
      .padding()
    }
  }

  private var title: String? {
    switch article.kindWithValue {
    case let .note(note):
      return note.title
    case let .medium(medium):
      return medium.title
    case nil:
      return nil
    }
  }
}

