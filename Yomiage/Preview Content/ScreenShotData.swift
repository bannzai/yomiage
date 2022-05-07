import Foundation

enum ScreenShotData {
  static let articles: [Article] = [
    .init(id: "1", kind: "note", pageURL: "https://note.com/bannzai/n/na4d72d2804f8", note: .init(title: "コーヒーと背中の鈍痛", author: "bannzai", eyeCatchImageURL: "https://assets.st-note.com/production/uploads/images/72213940/rectangle_large_type_2_036e079be07c579cab4ec47e49d4b603.jpeg?width=800", createdDate: .init()), medium: nil, createdDate: .init()),
    .init(id: "2", kind: "note", pageURL: "https://note.com/bannzai/n/na4d72d2804f8", note: .init(title: "クソアプリアドカレで実用的なスターを送れるアプリを作ってしまった", author: "07Morimi", eyeCatchImageURL: "https://storage.googleapis.com/zenn-user-upload/7726c69479d3-20211215.png", createdDate: .init()), medium: nil, createdDate: .init()),
    .init(id: "3", kind: "note", pageURL: "https://note.com/bannzai/n/na4d72d2804f8", note: .init(title: "僕がエンジニアになるまで物語", author: "hockam", eyeCatchImageURL: "https://pbs.twimg.com/media/EfIoFtPUYAAZL7g?format=jpg&name=large", createdDate: .init()), medium: nil, createdDate: .init()),
  ].reversed()
}
