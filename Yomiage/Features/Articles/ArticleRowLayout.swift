import SwiftUI

struct ArticleRowLayout<
  ThumbnailImage: View,
  PlayButton: View,
  WebViewButton: View
> : View {
  @ViewBuilder let thumbnailImage: ThumbnailImage
  @ViewBuilder let title: Text
  @ViewBuilder let author: Text
  @ViewBuilder let playButton: PlayButton
  @ViewBuilder let webViewButton: WebViewButton

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

      Spacer()

      HStack(spacing: 4) {
        playButton
        webViewButton
      }
    }
  }
}

