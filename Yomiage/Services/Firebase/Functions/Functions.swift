import Foundation
import FirebaseFunctions

typealias Functions = FirebaseFunctions.Functions
let functions = FirebaseFunctions.Functions.functions(region: "asia-northeast1")

// MARK: - html_to_ssml
extension Functions {
  struct HTMLToSSML: Codable {
    let ssml: String
    let article: Article

    struct Article: Codable {
      var pageURL: String
      var title: String?
      var author: String?
      var eyeCatchImageURL: String?
      var sections: [Section]

      struct Section: Codable {
        var title: String
        var content: String
      }
    }

    func articleSectionString() -> String {
      article.sections.reduce(into: "") { result, element in
        result += element.title + "\n\n\n"
        result += element.content + "\n"
      }
    }
  }
  func htmlToSSML(url: URL, html: String) async throws -> HTMLToSSML {
    let result = try await httpsCallable("html_to_ssml").call(["url": url.relativeString, "html": html])
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

