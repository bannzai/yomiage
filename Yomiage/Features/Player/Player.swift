import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  var allArticle: [Article] = []
  @Published private(set) var playingArticle: Article?
  @Published var error: Error?

  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let outputAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
  private let synthesizer = AVSpeechSynthesizer()

  private var canceller: Set<AnyCancellable> = []
  private var progress: Progress?
  private var writingAudioFile: AVAudioFile?

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)

        self?.reflectProperty()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)

        self?.reflectProperty()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)

        self?.reflectProperty()
      }.store(in: &canceller)

    synthesizer.delegate = self

    audioEngine.attach(playerNode)
    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputAudioFormat)
    audioEngine.prepare()

    setupRemoteTransportControls()
  }

  @MainActor func start(article: Article) async {
    guard let pageURL = URL(string: article.pageURL), let kind = article.kindWithValue else {
      return
    }

    do {
      let title: String
      let body: String
      switch kind {
      case let .note(note):
        title = note.title
        body = try await loadNoteBody(url: pageURL)
      case let .medium(medium):
        title = medium.title
        body = try await loadMediumBody(url: pageURL)
      }

      playingArticle = article

      configurePlayingCenter(title: title)
      speak(text: body)
    } catch {
      self.error = error
    }
  }

  func configurePlayingCenter(title: String) {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: rate
    ]
    MPNowPlayingInfoCenter.default().playbackState = .playing
  }

  func stop() {
    reset()
  }

  func backword(previousArticle: Article) async {
    reset()

    await start(article: previousArticle)
  }

  func forward(nextArticle: Article) async {
    reset()

    await start(article: nextArticle)
  }

  func previousArticle() -> Article? {
    guard
      let playingArticle = playingArticle,
      let index = allArticle.firstIndex(of: playingArticle),
      index > 0
    else {
      return nil
    }

    return allArticle[index - 1]
  }

  func nextArticle() -> Article? {
    guard
      let playingArticle = playingArticle,
      let index = allArticle.firstIndex(of: playingArticle),
      allArticle.count > index + 1
    else {
      return nil
    }

    return allArticle[index + 1]
  }

  func setupRemoteTransportControls() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { event in
      if !self.synthesizer.isPaused {
        return .commandFailed
      }

      self.synthesizer.continueSpeaking()
      return .success
    }
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { event in
      if self.synthesizer.isPaused {
        return .commandFailed
      }

      self.synthesizer.pauseSpeaking(at: .immediate)
      return .success
    }
    MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { event in
      guard let nextArticle = self.nextArticle() else {
        return .commandFailed
      }
      Task { @MainActor in
        await self.forward(nextArticle: nextArticle)
      }
      return .success
    }
    MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { event in
      guard let previousArticle = self.previousArticle() else {
        return .commandFailed
      }
      Task { @MainActor in
        await self.backword(previousArticle: previousArticle)
      }
      return .success
    }
  }

  // MARK: - Private
  private func speak(text: String) {
    guard let playingArticleID = playingArticle?.id else {
      return
    }

    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    func read(file: AVAudioFile, into buffer: AVAudioPCMBuffer) -> Bool {
      do {
        try file.read(into: buffer)
        return true
      } catch {
        // Ignore error
        print(error)
        return false
      }
    }
    if let readOnlyFile = try? AVAudioFile(forReading: cachedAudioFileURL(playingArticleID: playingArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
       let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: readOnlyFile.processingFormat, frameCapacity: AVAudioFrameCount(readOnlyFile.length)),
       read(file: readOnlyFile, into: cachedPCMBuffer) {
      play(pcmBuffer: cachedPCMBuffer) { [weak self] in
        DispatchQueue.main.async {
          self?.reset()
        }
      }
    } else {
      synthesizer.write(utterance) { [weak self] buffer in
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
          return
        }
        if pcmBuffer.frameLength == 0 {
          return
        }

        self?.play(pcmBuffer: pcmBuffer, completionHandler: nil)

        do {
          if self?.writingAudioFile == nil {
            self?.writingAudioFile = try AVAudioFile(forWriting: writingAudioFileURL(playingArticleID: playingArticleID), settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
          }
          try self?.writingAudioFile?.write(from: pcmBuffer)
        } catch {
          // Ignore error
          print(error)
        }
      }
    }
  }

  // Ref: https://stackoverflow.com/questions/56999334/boost-increase-volume-of-text-to-speech-avspeechutterance-to-make-it-louder
  private func play(pcmBuffer: AVAudioPCMBuffer, completionHandler: (() -> Void)?) {
    // NOTE: SpeechSynthesizer PCM format is pcmFormatInt16
    // it must be convert to .pcmFormatFloat32 if use pcmFormatInt16 to crash
    // ref: https://developer.apple.com/forums/thread/27674
    let converter = AVAudioConverter(
      from: AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 22050,
        channels: 1,
        interleaved: false
      )!,
      to: outputAudioFormat
    )
    let convertedBuffer = AVAudioPCMBuffer(
      pcmFormat: AVAudioFormat(
        commonFormat: outputAudioFormat.commonFormat,
        sampleRate: pcmBuffer.format.sampleRate,
        channels: pcmBuffer.format.channelCount,
        interleaved: false
      )!,
      frameCapacity: pcmBuffer.frameCapacity
    )!
    try! converter?.convert(to: convertedBuffer, from: pcmBuffer)

    playerNode.scheduleBuffer(convertedBuffer, at: nil, completionHandler: completionHandler)

    do {
      try audioEngine.start()
    } catch {
      fatalError(error.localizedDescription)
    }
    playerNode.play()
  }

  private func reflectProperty() {
    // NOTE: After update @Published property(volume,rate,pitch), other @Published property cannot be updated. So should run to the next run loop.
    DispatchQueue.main.async {
      // NOTE: Keep vlaue for avoid flushing after synthesizer.stopSpeaking -> speechSynthesizer(:didCancel).
      let _remainingText = self.progress?.remainingText

      // NOTE: call synthesizer.speak is not speaking and is broken synthesizer when synthesizer.isSpeaking
      guard self.synthesizer.isSpeaking else {
        return
      }
      self.synthesizer.stopSpeaking(at: .word)

      if let remainingText = _remainingText {
        self.speak(text: remainingText)
      }
    }
  }

  private func reset() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    if playerNode.isPlaying {
      playerNode.stop()
    }

    progress = nil
    playingArticle = nil
    writingAudioFile = nil

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    MPNowPlayingInfoCenter.default().playbackState = .stopped
  }
}

extension Player: AVAudioPlayerDelegate {

}

extension Player {
  enum DefaultValues {
    static let volume: Float = 0.5
    static let rate: Float = 0.53
    static let pitch: Float = 1.0

    static func setup() {
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerVolume) {
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)
      }
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerRate) {
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)
      }
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerPitch) {
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)
      }
    }
  }
}

extension Player: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print(#function)

    // Migrate temporary file to cache file when did finish speech
    do {
      if let playingArticleID = playingArticle?.id,
         let wroteAudioFile = try? AVAudioFile(forReading: writingAudioFileURL(playingArticleID: playingArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
         let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: wroteAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(wroteAudioFile.length)) {
        try wroteAudioFile.read(into: cachedPCMBuffer)

        let cachedAudioFile = try AVAudioFile(forWriting: cachedAudioFileURL(playingArticleID: playingArticleID), settings: cachedPCMBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
        try cachedAudioFile.write(from: cachedPCMBuffer)
      }
    } catch {
      // Ignore error
      print(error)
    }

    reset()
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print(#function)

    progress = nil
  }

  private struct Progress {
    let range: Range<String.Index>
    let lastWord: String
    let remainingText: String
    let speechText: String
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    print(#function)

    guard let range = Range(characterRange, in: utterance.speechString) else {
      return
    }

    let lastWord = String(utterance.speechString[range])
    let remainingText = String(utterance.speechString.suffix(from: range.upperBound))
    progress = .init(
      range: range,
      lastWord: lastWord,
      remainingText: remainingText,
      speechText: utterance.speechString
    )
  }
}

// MARK: - Utility
private func cachedAudioFileURL(playingArticleID: String) -> URL {
  let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
  return cacheDir.appendingPathComponent("v1-cached-\(playingArticleID)")
}

private func writingAudioFileURL(playingArticleID: String) -> URL {
  let tmpDir = URL(string: NSTemporaryDirectory())!
  return tmpDir.appendingPathComponent("v1-writing-\(playingArticleID)")
}

