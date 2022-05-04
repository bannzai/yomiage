import Foundation

extension String: LocalizedError {
  public var errorDescription: String? { "エラーが発生しました" }
  public var failureReason: String? { self }
}
