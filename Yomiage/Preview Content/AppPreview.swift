import SwiftUI

struct Previews_Preview: PreviewProvider {
  static var previews: some View {
    ZStack(alignment: .bottomTrailing) {
      Image(systemName: "gearshape")
        .foregroundColor(Color(.systemGray))

      Image(systemName: "speaker.fill")
        .font(.caption2)
        .foregroundColor(.label)
    }
  }
}

