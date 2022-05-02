import SwiftUI

final class AddArticleHTMLLoader: ObservableObject {
    @Environment(\.articleDatastore) private var articleDatastore

    @Published private var loadedURL: URL?

    func load(url: URL) {

    }
}

