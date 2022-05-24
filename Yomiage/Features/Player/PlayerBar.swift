import SwiftUI

struct PlayerBar: View {
  @EnvironmentObject var player: Player

  let article: Article

  var body: some View {
    VStack {
      Divider()

      if let title = title {
        Text(title)
          .font(.subheadline.weight(.medium))
          .padding(.top)
      }

      HStack {
        Button {
          analytics.logEvent("player_bar_backword_button_pressed", parameters: ["article_id": String(describing: article.id)])

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
          analytics.logEvent("player_bar_forward_button_pressed", parameters: ["article_id": String(describing: article.id)])

          player.stop()
        } label: {
          Image(systemName: "forward.frame.fill")
            .font(.body.weight(.heavy))
            .foregroundColor(.label)
            .padding()
        }
      }
      .padding()

      Divider()
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, 40)
    .background(Color.white)
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

