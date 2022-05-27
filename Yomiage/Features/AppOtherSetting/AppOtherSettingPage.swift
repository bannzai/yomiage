import SwiftUI

struct AppOtherSettingPage: View {
  var body: some View {
    List {
      Section("アプリについて") {
        NavigationLink {
          WebView(url: .init(string: "https://docs.google.com/forms/d/e/1FAIpQLSdE-Dr37Gr8_tPUsF1HBpZroJPXpp4AcDl6YkbaQ4shJ4SCRw/viewform?usp=sf_link")!)
            .navigationTitle("お問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("お問い合わせ")
        }

        NavigationLink {
          WebView(url: .init(string: "https://bannzai.github.io/yomiage/Terms")!)
            .navigationTitle("利用規約")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("利用規約")
        }

        NavigationLink {
          WebView(url: .init(string: "https://bannzai.github.io/yomiage/PrivacyPolicy")!)
            .navigationTitle("プライバシーポリシー")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("プライバシーポリシー")
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("その他")
  }
}

