import SwiftUI

struct AppOtherSettingPage: View {
  var body: some View {
    List {
      Section("アプリについて") {
        NavigationLink {
          SafariView(url: .init(string: "https://bannzai.github.io/yomiage/Terms")!)
        } label: {
          Text("利用規約")
        }

        NavigationLink {
          SafariView(url: .init(string: "https://bannzai.github.io/yomiage/PrivacyPolicy")!)
        } label: {
          Text("プライバシーポリシー")
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("その他")
  }
}

