import SwiftUI

struct AddArticleSheet: View {
    @StateObject private var loader = AddArticleHTMLLoader()
    @State private var text: String = ""
    private var url: URL? { .init(string: text) }

    var body: some View {
        VStack {
            TextField("https://", text: $text)

            Button {
                if let url = url {
                    loader.load(url: url)
                }
            } label: {
                Text("追加する")
            }
            .buttonStyle(.primary)
            .disabled(url == nil)
        }
        .frame(alignment: .top)
        .padding(.vertical, 20)
    }

}

