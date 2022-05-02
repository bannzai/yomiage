import SwiftUI
import FirebaseFirestore

struct ArticlesState: ObservableObject {
    @Environment(\.database) var database

    @Published var articles: [Article] = []

    func stream() -> AsyncThrowingStream<[Article] {
        database
            .collection(<#T##collectionPath: String##String#>)
            .addSnapshotsInSyncListener {
            <#code#>
        }
    }
}
