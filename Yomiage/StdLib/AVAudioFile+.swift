import Foundation
import AVFoundation

extension AVAudioFile {
  static func filePath(for pageURL: URL) -> URL {
    let tmpDir = URL(string: NSTemporaryDirectory())!
    return tmpDir
      .appendingPathComponent("v1")
      .appendingPathComponent(pageURL.path(percentEncoded: false))
  }

  static func isExist(for pageURL: URL) -> Bool {
    let fileURL = filePath(for: pageURL)
    return FileManager.default.fileExists(atPath: fileURL.absoluteString)
  }
}

