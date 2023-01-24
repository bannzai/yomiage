import SwiftUI

struct MediumArticle: View {
  @EnvironmentObject private var player: Player

  let article: Article
  let mediumArticle: Article.Medium?

  var body: some View {
    if let mediumArticle = mediumArticle {
      ZStack {
        ArticleRowLayout(
          article: article,
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
          }
        )
        .padding()
        .errorAlert(error: $player.error)
      }
    }
  }
}


