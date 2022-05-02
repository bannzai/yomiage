import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Article: Decodable {
    @DocumentID var id: String?

    let kind: String
    let note: Note?
    let medium: Medium?

    // MARK: - Kind
    var typedKind: Kind? { .init(rawValue: kind) }
    enum Kind: String {
        case note
        case medium
    }

    // MARK: - Each Kind Structure
    struct Note: Codable {
        let title: String
        let pageURL: String
        let author: String
        let eyeCatchImageURL: String?
        let createdDate: Timestamp
    }

    struct Medium: Codable {
        let title: String
        let pageURL: String
        let author: String
        let eyeCatchImageURL: String?
        let createdDate: Timestamp
    }
}
