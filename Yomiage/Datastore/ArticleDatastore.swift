import SwiftUI

struct ArticleDatastore {
  // TODO: Pagenation
  func articlesStream() -> AsyncThrowingStream<[Article], Error> {
    UserDatabase.shared.articlesReference()
      .order(by: "createdDate", descending: true)
      .stream()
  }

  func create(article: Article) async throws {
    try await UserDatabase.shared.articlesReference().addDocument(entity: article)
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
