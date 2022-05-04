import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Article: Codable, Equatable, Identifiable {
  @DocumentID var id: String?

  let kind: String
  let pageURL: String
  var note: Note?
  var medium: Medium?
  let createdDate: Timestamp

  // MARK: - Kind
  var typedKind: Kind? { .init(rawValue: kind) }
  enum Kind: String {
    case note
    case medium
  }

  // MARK: - Each Kind Structure
  struct Note: Codable, Equatable {
    let title: String
    let author: String
    let eyeCatchImageURL: String?
    let createdDate: Timestamp
  }

  struct Medium: Codable, Equatable {
    let title: String
    let author: String
    let eyeCatchImageURL: String?
    let createdDate: Timestamp
  }
}
