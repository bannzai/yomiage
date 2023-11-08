import Foundation
import FirebaseFirestore

struct Article: Codable, Equatable, Hashable, Identifiable {
  @DocumentID var id: String?
  let pageURL: String
  let title: String
  let author: String
  let eyeCatchImageURL: String?
  let createdDate: Timestamp
}
