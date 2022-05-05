import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

private let firestore = Firestore.firestore()

final class UserDatabase {
  private var userID: String!
  private init() { }
  static let shared = UserDatabase()

  func setUserID(_ userID: String) {
    assert(self.userID == nil)
    self.userID = userID
  }

  func articleReference(articleID: String) -> DocumentReference {
    firestore.document(.article(userID: userID, articleID: articleID))
  }
  func articlesReference() -> CollectionReference {
    firestore.collection(.articles(userID: userID))
  }
}

extension CollectionReference {
  func stream<T: Decodable>() -> AsyncThrowingStream<[T], Error> {
    .init { continuation in
      let registration = addSnapshotListener { snapshot, error in
        if let error = error {
          continuation.finish(throwing: error)
        } else if let snapshot = snapshot {
          do {
            continuation.yield(
              try snapshot.documents.map { try $0.data(as: T.self) }
            )
          } catch {
            continuation.finish(throwing: error)
          }
        } else {
          fatalError()
        }
      }

      continuation.onTermination = { @Sendable _ in
        registration.remove()
      }
    }
  }

  func addDocument<T: Encodable>(entity: T) async throws {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        _ = try addDocument(from: entity, completion: { error in
          if let error = error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: ())
          }
        })
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}

extension DocumentReference {
  func stream<T: Decodable>() -> AsyncThrowingStream<T, Error> {
    .init { continuation in
      let registration = addSnapshotListener { snapshot, error in
        if let error = error {
          continuation.finish(throwing: error)
        } else if let snapshot = snapshot {
          do {
            continuation.yield(
              try snapshot.data(as: T.self)
            )
          } catch {
            continuation.finish(throwing: error)
          }
        } else {
          fatalError()
        }
      }

      continuation.onTermination = { @Sendable _ in
        registration.remove()
      }
    }
  }
}


fileprivate extension String {
  static func user(userID: String) -> String { "/users/\(userID)" }
  static func articles(userID: String) -> String { "/users/\(userID)/articles" }
  static func article(userID: String, articleID: String) -> String { "/users/\(userID)/articles/\(articleID)" }
}
