import AVFoundation
import SwiftUI

struct ArticleRowLayout<
  ThumbnailImage: View
> : View {
  @EnvironmentObject var player: Player

  let article: Article

  @ViewBuilder let thumbnailImage: ThumbnailImage
  @ViewBuilder let title: Text
  @ViewBuilder let author: Text

  var body: some View {
    HStack {
      thumbnailImage
        .frame(width: 60, height: 60)
        .background(Color(.systemGray5))
        .cornerRadius(8)

      VStack(alignment: .leading, spacing: 10) {
        title
          .font(.system(.headline))
        author
          .font(.system(.caption))
      }
      .layoutPriority(2)

      Spacer()
        .layoutPriority(1)

      HStack(spacing: 4) {
        if let pageURL = URL(string: article.pageURL), !AVAudioFile.isExist(for: pageURL) {
          DownloadButton(article: article)
        } else if player.isPlaying {
          PauseButton(article: article)
        } else {
          PlayButton(article: article)
        }

        NavigationLinkButton {
          ArticleWebViewPage(article: article)
        } label: {
          Image(systemName: "safari")
            .frame(width: 14, height: 14)
            .foregroundColor(.label)
            .padding()
        }
      }
    }
  }
}

