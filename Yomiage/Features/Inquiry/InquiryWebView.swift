import SwiftUI
import WebKit

struct InquiryWebView: UIViewRepresentable {
  let htmlString = """
<html>
<body>
  <form method="post" action="https://hyperform.jp/api/67bIj5dJ">
    <label>お名前</label>
    <input name="お名前" type="text" required>
    <label>メールアドレス</label>
    <input name="email" type="email" required>
    <label>お問い合わせ内容</label>
    <textarea name="お問い合わせ内容"></textarea>
    <input name="個人情報の利用についての同意" id="consent-check" type="checkbox" value="同意します" required>
    <label for="consent-check">個人情報の利用についての同意</label>
    <button type="submit">送信</button>
  </form>
</body>
</html>
"""
  
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView(frame: .zero)
    webView.loadHTMLString(htmlString, baseURL: nil)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}
}
