import Foundation

// Reference: https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/13
// TODO: not working with loadHTML(url:)
public func withTimeout<T>(
  seconds: Foundation.TimeInterval,
  operation: @escaping @Sendable () async throws -> T
) async throws -> T {
  try await withThrowingTaskGroup(of: T.self) { group in
    group.addTask {
      try await operation()
    }

    group.addTask {
      if seconds > 0 {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
      }
      try Task.checkCancellation()
      throw TimedOutError()
    }

    defer{
      group.cancelAll()
    }

    do {
      let result = try await group.next()!
      return result
    } catch {
      print("[DEBUG]", "error: \(error)")
      throw error
    }
  }
}

private struct TimedOutError: LocalizedError {
  var errorDescription: String? {
    "タイムアウトしました"
  }
  var failureReason: String? {
    "一定時間が経過したため処理を中断しました。再度お試しください"
  }
  var recoverySuggestion: String? = nil
  var helpAnchor: String? = nil
}
