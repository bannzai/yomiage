import SwiftUI

struct Previews_Preview: PreviewProvider {
  static var previews: some View {
    ZStack(alignment: .bottomTrailing) {
      Image(systemName: "speaker.fill")
        .font(.title2)
        .foregroundColor(.label)

      Image(systemName: "gearshape")
        .font(.caption2)
        .foregroundColor(Color(.systemGray))
    }
  }
}

