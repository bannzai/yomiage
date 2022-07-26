import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  // @Published state for audio controls
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  // @Published state for database entity
  @Published private(set) var targetArticle: Article?
  @Published var error: Error?

  // @Published state for Player events
  @Published private(set) var spoken: Void = ()
  @Published private(set) var paused: Void = ()

  // Non @Published statuses
  var allArticle: [Article] = []
  private var canceller: Set<AnyCancellable> = []

  private enum Const {
    static let outputAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
  }

  // Audio Player components
  private let synthesizer = AVSpeechSynthesizer()
  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()

  // Temporary state on playing article
  // It is not contains targetArticle because keep last played article and displyaing and possible to replay it on `remote control center`, `PlayerBar`
  private var progress: Progress?
  private var writingAudioFile: AVAudioFile?

  var isPlaying: Bool {
    playerNode.isPlaying
  }

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)

        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)

        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)

        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)

    synthesizer.delegate = self

    audioEngine.attach(playerNode)
    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: Const.outputAudioFormat)
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

      targetArticle = article

      configurePlayingCenter(title: title)
      play(text: body)
    } catch {
      self.error = error
    }
  }

  func pause() {
    pauseAudioComponents()
    paused = ()
  }

  func backword() async {
    guard let previousArticle = self.previousArticle() else {
      return
    }

    pauseAudioComponents()
    await start(article: previousArticle)
  }

  func forward() async {
    guard let nextArticle = self.nextArticle() else {
      return
    }

    pauseAudioComponents()
    await start(article: nextArticle)
  }

  func setupRemoteTransportControls() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { [self] event in
      if isPlaying {
        return .commandFailed
      }

      pauseAudioComponents()
      return .success
    }
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { [self] event in
      if !isPlaying {
        return .commandFailed
      }

      pauseAudioComponents()
      return .success
    }
    MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [self] event in
      guard let _ = nextArticle() else {
        return .commandFailed
      }
      Task { @MainActor in
        await forward()
      }
      return .success
    }
    MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [self] event in
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

extension Player {
// MARK: - Private
  private func play(text: String) {
    guard let targetArticleID = targetArticle?.id else {
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
    if let readOnlyFile = try? AVAudioFile(forReading: cachedAudioFileURL(targetArticleID: targetArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
       let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: readOnlyFile.processingFormat, frameCapacity: AVAudioFrameCount(readOnlyFile.length)),
       read(file: readOnlyFile, into: cachedPCMBuffer) {
      speak(pcmBuffer: cachedPCMBuffer) { [weak self] in
        DispatchQueue.main.async {
          self?.pauseAudioComponents()
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

        self?.speak(pcmBuffer: pcmBuffer, completionHandler: nil)
        self?.spoken = ()

        do {
          if self?.writingAudioFile == nil {
            self?.writingAudioFile = try AVAudioFile(forWriting: writingAudioFileURL(targetArticleID: targetArticleID), settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
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
  private func speak(pcmBuffer: AVAudioPCMBuffer, completionHandler: (() -> Void)?) {
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
      to: Const.outputAudioFormat
    )
    let convertedBuffer = AVAudioPCMBuffer(
      pcmFormat: AVAudioFormat(
        commonFormat: Const.outputAudioFormat.commonFormat,
        sampleRate: pcmBuffer.format.sampleRate,
        channels: pcmBuffer.format.channelCount,
        interleaved: false
      )!,
      frameCapacity: pcmBuffer.frameCapacity
    )!

    do {
      try converter?.convert(to: convertedBuffer, from: pcmBuffer)
      playerNode.scheduleBuffer(convertedBuffer, at: nil, completionHandler: completionHandler)
      try audioEngine.start()
      playerNode.play()
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  private func configurePlayingCenter(title: String) {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: rate
    ]
  }

  private func reloadWhenUpdatedPlayerSetting() {
    // NOTE: After update @Published property(volume,rate,pitch), other @Published property cannot be updated. So should run to the next run loop.
    DispatchQueue.main.async {
      // NOTE: Keep vlaue for avoid flushing after synthesizer.stopSpeaking -> speechSynthesizer(:didCancel).
      let _remainingText = self.progress?.remainingText

      pauseAudioComponents()
      
      if let remainingText = _remainingText {
        self.play(text: remainingText)
      }
    }
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

  private func replayAudioComponent() {}

  private func pauseAudioComponents() {
    // NOTE: syntesizer is broken when call synthesizer.stopSpeaking when synthesizer is not speaking
    if synthesizer.isSpeaking {
      synthesizer.pauseSpeaking(at: .immediate)
    }
    if audioEngine.isRunning {
      audioEngine.pause()
    }
    if playerNode.isPlaying {
      playerNode.pause()
    }
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
      if let targetArticleID = targetArticle?.id,
         let wroteAudioFile = try? AVAudioFile(forReading: writingAudioFileURL(targetArticleID: targetArticleID), commonFormat: .pcmFormatInt16, interleaved: false),
         let cachedPCMBuffer = AVAudioPCMBuffer(pcmFormat: wroteAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(wroteAudioFile.length)) {
        try wroteAudioFile.read(into: cachedPCMBuffer)

        let cachedAudioFile = try AVAudioFile(forWriting: cachedAudioFileURL(targetArticleID: targetArticleID), settings: cachedPCMBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
        try cachedAudioFile.write(from: cachedPCMBuffer)
      }
    } catch {
      // Ignore error
      print(error)
    }

    pauseAudioComponents()
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
private func cachedAudioFileURL(targetArticleID: String) -> URL {
  let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
  return cacheDir.appendingPathComponent("v1-cached-\(targetArticleID)")
}

private func writingAudioFileURL(targetArticleID: String) -> URL {
  let tmpDir = URL(string: NSTemporaryDirectory())!
  return tmpDir.appendingPathComponent("v1-writing-\(targetArticleID)")
}

