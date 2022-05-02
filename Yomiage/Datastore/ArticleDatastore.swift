import SwiftUI

struct ArticleDatastore {
    // TODO: Pagenation
    func articlesStream() -> AsyncThrowingStream<[Article], Error> {
        UserDatabase.shared.articlesReference().stream()
    }
}

struct ArticleDatastoreEnvironmentKey: EnvironmentKey {
    static var defaultValue: ArticleDatastore = .init()
}

extension EnvironmentValues {
    var articleDatastore: ArticleDatastore {
        get { self[ArticleDatastoreEnvironmentKey.self] }
        set { self[ArticleDatastoreEnvironmentKey.self] = newValue }
    }
}
