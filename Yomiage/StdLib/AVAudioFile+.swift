import Foundation
import AVFoundation

extension AVAudioFile {
  static func filePath(for pageURL: URL) -> URL {
    let tmpDir = URL(string: NSTemporaryDirectory())!
    // Can't use not create nested directory
    return tmpDir
      .appendingPathComponent("v1-\(pageURL.path(percentEncoded: true).replacingOccurrences(of: "/", with: "___"))")
  }

  static func isExist(for pageURL: URL) -> Bool {
    let fileURL = filePath(for: pageURL)
    return FileManager.default.fileExists(atPath: fileURL.absoluteString)
  }
}

