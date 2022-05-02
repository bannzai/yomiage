import SwiftUI

extension View {
  func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
    let alertError = AlertError(error: error.wrappedValue)

    return alert(isPresented: .constant(alertError != nil), error: alertError) { _ in
      Button(buttonTitle) {
        error.wrappedValue = nil
      }
    } message: { error in
      Text(error.failureReason ?? "")
    }
  }
}

private struct AlertError: LocalizedError {
  let underlyingLocalizedError: LocalizedError
  init?(error: Error?) {
    guard let localizedError = error as? LocalizedError else {
      return nil
    }

    underlyingLocalizedError = localizedError
  }

  var errorDescription: String? {
    underlyingLocalizedError.errorDescription
  }
  var failureReason: String? {
    underlyingLocalizedError.failureReason
  }
}
