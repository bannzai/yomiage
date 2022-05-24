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
        AsyncButton {
          analytics.logEvent("player_bar_backword_button_pressed", parameters: ["article_id": String(describing: article.id)])

          await player.backword()
        } label: {
          Image(systemName: "backward.frame.fill")
            .padding()
        } progress: {
          ProgressView()
        }
        Spacer()

        Button {
          analytics.logEvent("player_bar_play_button_pressed", parameters: ["article_id": String(describing: article.id)])

          player.stop()
        } label: {
          Image(systemName: "stop.fill")
            .padding()
        }
        Spacer()

        AsyncButton {
          analytics.logEvent("player_bar_forward_button_pressed", parameters: ["article_id": String(describing: article.id)])

          await player.forward()
        } label: {
          Image(systemName: "forward.frame.fill")
            .padding()
        } progress: {
          ProgressView()
        }
      }
      .font(.title)
      .foregroundColor(.label)
      .padding()

      Divider()
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, 40)
    .background(Color(.secondarySystemBackground))
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

