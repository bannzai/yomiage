import Foundation
import AVFoundation

extension AVAudioFile {
  static func filePath(for pageURL: URL) -> URL {
    let tmpDir = URL(string: NSTemporaryDirectory())!
    return tmpDir
      .appendingPathComponent("v1")
      .appendingPathComponent(pageURL.path(percentEncoded: false))
  }
}

