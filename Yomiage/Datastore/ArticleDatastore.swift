import Foundation

struct ArticleDatastore {
    // TODO: Pagenation
    func articlesStream() -> AsyncThrowingStream<[Article], Error> {
        UserDatabase.shared.articlesReference().stream()
    }
}
