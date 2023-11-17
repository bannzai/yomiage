import SwiftUI

struct VSpacer: View {
  let height: CGFloat

  init(_ height: CGFloat) {
    self.height = height
  }

  var body: some View {
let _ = Self._printChanges()
    Spacer()
      .frame(height: height)
  }
}

struct HSpacer: View {
  let width: CGFloat

  init(_ width: CGFloat) {
    self.width = width
  }

  var body: some View {
let _ = Self._printChanges()
    Spacer()
      .frame(width: width)
  }
}


