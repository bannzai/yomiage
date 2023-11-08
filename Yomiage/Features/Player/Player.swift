import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  private enum Const {
    static let outputAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
  }

  @AppStorage(.playerRate) var rate: Double {
    didSet {
      player?.rate = Float(rate)
    }
  }

  // @Published state for Player events
  @Published private(set) var finished: Void = ()
  @Published private(set) var stopped: Void = ()
  @Published private(set) var paused: Void = ()
  @Published private(set) var resumed: Void = ()

  // @Published status for View
  @Published private(set) var playingArticle: Article?
  @Published var error: Error?

  // Non @Published statuses
  var allArticle: [Article] = []

  // Audio Player components
  var player: AVAudioPlayer?

  // Temporary state on playing article
  private var writingAudioFile: AVAudioFile?

  var isPlaying: Bool {
    player?.isPlaying == true
  }

  @MainActor func play(article: Article) {
    guard let pageURL = URL(string: article.pageURL) else {
      return
    }

    do {
      player = try AVAudioPlayer(contentsOf: AVAudioFile.filePath(for: pageURL))
      player?.enableRate = true
      player?.rate = Float(rate)
      player?.delegate = self
      player?.play()
    } catch {
      fatalError(error.localizedDescription)
    }

    playingArticle = article

    configurePlayingCenter(title: article.title ?? "Unknown title")
  }

  func pause() {
    player?.pause()
    paused = ()
  }

  func resume() {
    player?.play()
    resumed = ()
  }

  func stop() {
    player?.stop()
    player = nil
    playingArticle = nil
    stopped = ()
  }

  func backword() async {
    guard let previousArticle = self.previousArticle() else {
      return
    }

    pause()
    await play(article: previousArticle)
  }

  func forward() async {
    guard let nextArticle = self.nextArticle() else {
      return
    }

    pause()
    await play(article: nextArticle)
  }

  func setupRemoteTransportControls() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [self] event in
      print("#playCommand", "isPlaying: \(isPlaying)")
      if isPlaying {
        return .commandFailed
      }

      player?.play()
      return .success
    }
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { [self] event in
      print("#pauseCommand", "isPlaying: \(isPlaying)")
      if !isPlaying {
        return .commandFailed
      }

      pause()
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

extension Player: AVAudioPlayerDelegate {
  public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    playingArticle = nil
    self.player = nil
    finished = ()
  }

  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {

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
      let playingArticle = playingArticle,
      let index = allArticle.firstIndex(of: playingArticle),
      index > 0
    else {
      return nil
    }

    return allArticle[index - 1]
  }

  private func nextArticle() -> Article? {
    guard
      let playingArticle = playingArticle,
      let index = allArticle.firstIndex(of: playingArticle),
      allArticle.count > index + 1
    else {
      return nil
    }

    return allArticle[index + 1]
  }
}


// TODO: Cacheの見直し。今まではplayやdidFinish等のタイミングで書き込んでいたが、そこに組み込むのは難しい。なのでダウンロードボタンを別途設けてこの機能たちを使っていく
// TODO: v1 -> v2
// MARK: - Cache
//extension Player {
//  func speakFromCache(playingArticleID: String) {
//    if let readOnlyFile = try? AVAudioFile(forReading: cachedAudioFileURL(playingArticleID: playingArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
//       let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: readOnlyFile.processingFormat, frameCapacity: AVAudioFrameCount(readOnlyFile.length)),
//       readCache(file: readOnlyFile, into: cachedPCMBuffer) {
//      speak(pcmBuffer: cachedPCMBuffer) { [weak self] in
//        DispatchQueue.main.async {
//          self?.pause()
//        }
//      }
//    }
//  }
//
//  func proceedWriteCache(playingArticleID: String, into pcmBuffer: AVAudioPCMBuffer) throws {
//    if writingAudioFile == nil {
//      writingAudioFile = try AVAudioFile(forWriting: writingAudioFileURL(playingArticleID: playingArticleID), settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
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
//      if let playingArticleID = playingArticle?.id,
//         let wroteAudioFile = try? AVAudioFile(forReading: writingAudioFileURL(playingArticleID: playingArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
//         let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: wroteAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(wroteAudioFile.length)) {
//        try wroteAudioFile.read(into: cachedPCMBuffer)
//
//        let cachedAudioFile = try AVAudioFile(forWriting: cachedAudioFileURL(playingArticleID: playingArticleID), settings: cachedPCMBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
//        try cachedAudioFile.write(from: cachedPCMBuffer)
//      }
//    } catch {
//      // Ignore error
//      print(error)
//    }
//  }
//
//  private func cachedAudioFileURL(playingArticleID: String) -> URL {
//    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//    return cacheDir.appendingPathComponent("v1-cached-\(playingArticleID)")
//  }
//
//}
