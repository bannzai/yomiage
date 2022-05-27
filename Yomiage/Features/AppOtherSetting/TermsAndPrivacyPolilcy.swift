import SwiftUI

struct TermsAndPrivacyPolilcy: View {
  var body: some View {
    HStack {
      Link("利用規約", destination: .init(string: "https://bannzai.github.io/yomiage/Terms")!)
        .font(.system(.footnote))
        .frame(maxWidth: .infinity)
      Divider()
        .foregroundColor(Color(.systemGray5))
        .frame(height: 30)
      Link("プライバシーポリシー", destination: .init(string: "https://bannzai.github.io/yomiage/PrivacyPolicy")!)
        .font(.system(.footnote))
        .frame(maxWidth: .infinity)
    }
  }
}

