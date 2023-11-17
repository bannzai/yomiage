import SwiftUI

struct MediumSheetLayout<Title: View, Content: View>: View {
  @ViewBuilder let title: Title
  @ViewBuilder let content: Content

  var body: some View {
let _ = Self._printChanges()
    VStack(spacing: 24) {
      title
      ScrollView(.vertical) {
        content
      }
    }
    .padding(.top, 30)
  }
}

