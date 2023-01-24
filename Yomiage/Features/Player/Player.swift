import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  private enum Const {
    static let outputAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
  }

  @AppStorage(.playerRate) var rate: Double

  // @Published state for Player events
  // Update View for each timing
  @Published private(set) var spoken: Void = ()
  @Published private(set) var paused: Void = ()

  // @Published status for presentation
  @Published private(set) var targetArticle: Article?
  @Published var error: Error?

  // Non @Published statuses
  var allArticle: [Article] = []

  // Audio Player components
  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()

  // Temporary state on playing article
  private var writingAudioFile: AVAudioFile?

  var isPlaying: Bool {
    playerNode.isPlaying
  }

  @MainActor func play(article: Article) async {
    guard let pageURL = URL(string: article.pageURL), let kind = article.kindWithValue else {
      return
    }
    targetArticle = article

    let title: String
    switch kind {
    case let .note(note):
      title = note.title
    case let .medium(medium):
      title = medium.title
    }

    targetArticle = article
    configurePlayingCenter(title: title)
    stopAudioComponents()
    resetAudioEngine()

    do {
      let readOnlyFile = try AVAudioFile(forReading: AVAudioFile.filePath(for: pageURL), commonFormat: .pcmFormatInt16, interleaved: false)
      let buffer = AVAudioPCMBuffer(pcmFormat: readOnlyFile.processingFormat, frameCapacity: AVAudioFrameCount(readOnlyFile.length))!
      try readOnlyFile.read(into: buffer)
      await playerNode.scheduleBuffer(buffer, at: nil)
      try audioEngine.start()
      playerNode.play()
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  func pause() {
    pauseAudioComponents()
  }

  func backword() async {
    guard let previousArticle = self.previousArticle() else {
      return
    }

    pauseAudioComponents()
    await play(article: previousArticle)
  }

  func forward() async {
    guard let nextArticle = self.nextArticle() else {
      return
    }

    pauseAudioComponents()
    await play(article: nextArticle)
  }

  func resetAudioEngine() {
    playerNode.reset()
    audioEngine.reset()

    audioEngine.attach(playerNode)
    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: Const.outputAudioFormat)
    audioEngine.prepare()
  }

  func setupRemoteTransportControls() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [self] event in
      print("#playCommand", "isPlaying: \(isPlaying)")
      if isPlaying {
        return .commandFailed
      }

      replayAudioComponent()
      return .success
    }
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { [self] event in
      print("#pauseCommand", "isPlaying: \(isPlaying)")
      if !isPlaying {
        return .commandFailed
      }

      pauseAudioComponents()
      return .success
    }
    MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [self] event in
      print("#nextTrackCommand", "nextArticle: \(String(describing: nextArticle()))")
      guard let _ = nextArticle() else {
        return .commandFailed
      }
      Task { @MainActor in
        await forward()
      }
      return .success
    }
    MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [self] event in
      print("#previousTrackCommand", "previousArticle: \(String(describing: previousArticle()))")
      guard let _ = previousArticle() else {
        return .commandFailed
      }
      Task { @MainActor in
        await backword()
      }
      return .success
    }
  }
}

// MARK: - Private
extension Player {
  private func configurePlayingCenter(title: String) {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: rate
    ]
  }

  private func previousArticle() -> Article? {
    guard
      let targetArticle = targetArticle,
      let index = allArticle.firstIndex(of: targetArticle),
      index > 0
    else {
      return nil
    }

    return allArticle[index - 1]
  }

  private func nextArticle() -> Article? {
    guard
      let targetArticle = targetArticle,
      let index = allArticle.firstIndex(of: targetArticle),
      allArticle.count > index + 1
    else {
      return nil
    }

    return allArticle[index + 1]
  }

  private func replayAudioComponent() {
    do {
      try audioEngine.start()
      playerNode.play()
    } catch {
      // Ignore error
      print(error)
    }
  }

  private func pauseAudioComponents() {
    if audioEngine.isRunning {
      audioEngine.pause()
    }
    if playerNode.isPlaying {
      playerNode.pause()
    }
    paused = ()
  }

  private func stopAudioComponents() {
    audioEngine.stop()
    playerNode.stop()
  }
}


// TODO: Cacheの見直し。今まではplayやdidFinish等のタイミングで書き込んでいたが、そこに組み込むのは難しい。なのでダウンロードボタンを別途設けてこの機能たちを使っていく
// TODO: v1 -> v2
// MARK: - Cache
//extension Player {
//  func speakFromCache(targetArticleID: String) {
//    if let readOnlyFile = try? AVAudioFile(forReading: cachedAudioFileURL(targetArticleID: targetArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
//       let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: readOnlyFile.processingFormat, frameCapacity: AVAudioFrameCount(readOnlyFile.length)),
//       readCache(file: readOnlyFile, into: cachedPCMBuffer) {
//      speak(pcmBuffer: cachedPCMBuffer) { [weak self] in
//        DispatchQueue.main.async {
//          self?.pauseAudioComponents()
//        }
//      }
//    }
//  }
//
//  func proceedWriteCache(targetArticleID: String, into pcmBuffer: AVAudioPCMBuffer) throws {
//    if writingAudioFile == nil {
//      writingAudioFile = try AVAudioFile(forWriting: writingAudioFileURL(targetArticleID: targetArticleID), settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
//    }
//    try writingAudioFile?.write(from: pcmBuffer)
//  }
//
//  func readCache(file: AVAudioFile, into buffer: AVAudioPCMBuffer) -> Bool {
//    do {
//      try file.read(into: buffer)
//      return true
//    } catch {
//      // Ignore error
//      print(error)
//      return false
//    }
//  }
//
//  func migrateCache() {
//    // Migrate temporary file to cache file when did finish speech
//    do {
//      if let targetArticleID = targetArticle?.id,
//         let wroteAudioFile = try? AVAudioFile(forReading: writingAudioFileURL(targetArticleID: targetArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
//         let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: wroteAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(wroteAudioFile.length)) {
//        try wroteAudioFile.read(into: cachedPCMBuffer)
//
//        let cachedAudioFile = try AVAudioFile(forWriting: cachedAudioFileURL(targetArticleID: targetArticleID), settings: cachedPCMBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
//        try cachedAudioFile.write(from: cachedPCMBuffer)
//      }
//    } catch {
//      // Ignore error
//      print(error)
//    }
//  }
//
//  private func cachedAudioFileURL(targetArticleID: String) -> URL {
//    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//    return cacheDir.appendingPathComponent("v1-cached-\(targetArticleID)")
//  }
//
//}
