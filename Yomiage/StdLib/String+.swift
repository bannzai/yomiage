import Foundation

extension String {
  var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension String: LocalizedError {
  public var errorDescription: String? { "エラーが発生しました" }
  public var failureReason: String? { self }
}
