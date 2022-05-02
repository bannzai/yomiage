import SwiftUI
import Kanna

final class AddArticleHTMLLoader: ObservableObject, LoadHTMLLoader {
    @Environment(\.articleDatastore) private var articleDatastore

    typealias Target = (url: URL, Article.Kind)
    @Published private(set) var target: Target?
    @Published private(set) var error: LocalizedError?

    func load(url: URL) {
        switch url.host {
        case "note.com":
            target = (url, .note)
        case "medium.com":
            target = (url, .medium)
        case _:
            error = HostMismatchError()
        }
    }

    func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
        guard let target = target else {
            return
        }

        defer {
            self.target = nil
        }

        if let html = arguments.0 as? String {
            proceedRead(html: html, target: target)
        } else if let loadError = arguments.1 {
            error = WebViewLoadHTMLError(error: loadError)
        } else {
            error = WebViewLoadHTMLError(error: nil)
        }
    }

    private func proceedRead(html: String, target: Target) {
        if let doc = try? HTML(html: html, encoding: .utf8) {
            print(doc.title)

            // Search for nodes by CSS
            for link in doc.css("a, link") {
                print(link.text)
                print(link["href"])
            }

            // Search for nodes by XPath
            for link in doc.xpath("//a | //link") {
                print(link.text)
                print(link["href"])
            }
        }
    }
}


fileprivate struct HostMismatchError: LocalizedError {
    var errorDescription: String? {
        "対応していないURLです"
    }
    var failureReason: String? {
        "note.com,medium.comで記事が存在するURLを入力してください"
    }
    let helpAnchor: String? = nil
    let recoverySuggestion: String? = nil
}

fileprivate struct WebViewLoadHTMLError: LocalizedError {
    let error: Error?

    var errorDescription: String? {
        "再度読み込みをしてください"
    }
    var failureReason: String? {
        error?.localizedDescription ?? "読み込みに失敗しました"
    }
    let helpAnchor: String? = nil
    let recoverySuggestion: String? = nil
}
