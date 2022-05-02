import SwiftUI

struct ArticlesPage: View {
    @Environment(\.articleDatastore) var articleDatastore

    var body: some View {
        StreamView(stream: articleDatastore.articlesStream()) { articles in
            List {
                Group {
                    VStack {

                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        } errorContent: { error, reload in
            UniversalErrorView(error: error, reload: reload)
        } loading: {
            ProgressView()
        }
    }
}


struct ArticlesRow: View {
    var body: some View {
        HStack {
            
            VStack {

            }
        }
    }
}
