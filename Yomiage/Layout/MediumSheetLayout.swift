import SwiftUI

struct MediumSheetLayout<Title: View, Content: View>: View {
  @ViewBuilder let title: Title
  @ViewBuilder let content: Content

  var body: some View {
      VStack(spacing: 40) {
        title
        content
        Spacer()
      }
      .padding(.top, 30)
  }
}

