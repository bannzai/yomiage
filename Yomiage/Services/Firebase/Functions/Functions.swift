import Foundation
import FirebaseFunctions

let functions = FirebaseFunctions.Functions.functions(region: "asia-northeast1")

// MARK: - html_to_ssml
extension FirebaseFunctions.Functions {
  struct HTMLToSSML: Codable {
    let ssml: String
    let contentBlocks: [ContentBlock]

    struct ContentBlock: Codable {
      let title: String
      let content: String
    }
  }
  func htmlToSSML(url: String, html: String) async throws -> HTMLToSSML {
    let result = try await httpsCallable("html_to_ssml").call(["url": url, "html": html])
    return try result.decode()
  }
}

// MARK: - fileprivate
fileprivate extension HTTPSCallableResult {
  var json: [String: Any]? {
    if let result = data as? [String: Any], let d = result["data"] as? [String: Any] {
      return d
    } else {
      return nil
    }
  }

  enum DecodeError: LocalizedError {
    case jsonDataIsNotFound
    case jsonDataisInvalidFormat

    var errorDescription: String? {
      switch self {
      case .jsonDataIsNotFound: "JSON data is not found"
      case .jsonDataisInvalidFormat: "JSON is invalid format"
      }
    }
    var failureReason: String? {
      switch self {
      case .jsonDataIsNotFound: "Please check your internet connection and retry after"
      case .jsonDataisInvalidFormat: "Please check your internet connection and retry after"
      }
    }
  }

  func decode<T>() throws -> T where T: Decodable {
    guard let json else {
      throw DecodeError.jsonDataIsNotFound
    }
    if JSONSerialization.isValidJSONObject(json) {
      throw DecodeError.jsonDataisInvalidFormat
    }
    let data = try JSONSerialization.data (withJSONObject: json, options: [])
    return try JSONDecoder().decode(T.self, from: data)
  }
}

