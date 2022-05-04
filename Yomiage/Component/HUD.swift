import SwiftUI

struct HUD: View {
  var body: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.white.opacity(0.3))
  }
}

