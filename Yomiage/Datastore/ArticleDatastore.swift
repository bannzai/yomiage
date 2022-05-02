import Foundation

struct ArticleDatastore {
    private init() { }
    static let shared = ArticleDatastore()
    
    // TODO: Pagenation
    func articlesStream() -> AsyncThrowingStream<[Article], Error> {
        UserDatabase.shared.articlesReference().stream()
    }
}
