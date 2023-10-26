import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Article: Codable, Equatable, Hashable, Identifiable {
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
  struct Note: Codable, Equatable, Hashable {
    let title: String
    let author: String
    let eyeCatchImageURL: String?
    let createdDate: Timestamp
  }

  struct Medium: Codable, Equatable, Hashable {
    let title: String
    let author: String
    let eyeCatchImageURL: String?
    let createdDate: Timestamp
  }
}

extension Article {
  enum KindWithValue {
    case note(Note)
    case medium(Medium)
  }
  var kindWithValue: KindWithValue? {
    guard let typedKind = typedKind else {
      return nil
    }

    switch typedKind {
    case .note:
      if let note = note {
        return .note(note)
      }
    case .medium:
      if let medium = medium {
        return .medium(medium)
      }
    }

    assertionFailure("it is supported type. but actual article struct is nil \(self)")
    return nil
  }
}
