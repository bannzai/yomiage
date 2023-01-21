import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  // @Published state for audio controls
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  // @Published state for Player events
  // Update View for each timing
  @Published private(set) var spoken: Void = ()
  @Published private(set) var paused: Void = ()

  // @Published status for presentation
  @Published private(set) var targetArticle: Article?
  @Published var error: Error?


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
    resetAudioEngine()
    setupRemoteTransportControls()
  }

  @MainActor func start(article: Article) async {
    if targetArticle == article {
      let targetArticleIsInProgress = progress != nil
      if targetArticleIsInProgress {
        replayAudioComponent()
        return
      }
    }

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
      stopAudioComponents()
      resetAudioEngine()
      play(text: body)
    } catch {
      self.error = error
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
    await start(article: previousArticle)
  }

  func forward() async {
    guard let nextArticle = self.nextArticle() else {
      return
    }

    pauseAudioComponents()
    await start(article: nextArticle)
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

extension Player {
// MARK: - Private
  // NOTE: synthesizer.writeを呼び出す前に必ずsynthesizerは止まっている(!isPlaying && !isPaused)必要がある => stopAudioComponentsを事前に呼び出す
  private func play(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    //     TODO: Call speak if cache is exists
    //        speakFromCache(targetArticleID: targetArticleID)
    synthesizer.write(utterance) { [weak self] buffer in
      print("#synthesizer.write")
      guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
        return
      }
      if pcmBuffer.frameLength == 0 {
        return
      }

      print("pcmBuffer.frameLength:", pcmBuffer.frameLength)
      self?.speak(pcmBuffer: pcmBuffer, completionHandler: nil)
      self?.spoken = ()

      //         TODO: Call write cache
      //        try self?.proceedWriteCache(targetArticleID: targetArticleID, into: pcmBuffer)
    }
  }

  // Ref: https://stackoverflow.com/questions/56999334/boost-increase-volume-of-text-to-speech-avspeechutterance-to-make-it-louder
  private func speak(pcmBuffer: AVAudioPCMBuffer, completionHandler: (() -> Void)?) {
    // NOTE: SpeechSynthesizer PCM format is pcmFormatInt16
    // it must be convert to .pcmFormatFloat32 if use pcmFormatInt16
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
    // NOTE: 対象となる@Publishedなプロパティ(volume,rate,pitch)の更新はobjectWillChangeのタイミングで行われる。なので、更新後の値をプロパティアクセスからは取得できない。次のRunLoopで処理でプロパティアクセスするようにすることで更新後の値が取得できる
    DispatchQueue.main.async { [self] in
      // NOTE: 各関数の副作用の影響を受けないタイミングで、残りのテキストを一時変数に保持している
      let _remainingText = progress?.remainingText

      stopAudioComponents()

      if let remainingText = _remainingText {
        play(text: remainingText)
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

  private func replayAudioComponent() {
    do {
      synthesizer.continueSpeaking()
      try audioEngine.start()
      playerNode.play()
    } catch {
      // Ignore error
      print(error)
    }
  }

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
    paused = ()
  }

  private func stopAudioComponents() {
    // NOTE: syntesizer is broken when call synthesizer.stopSpeaking when synthesizer is not speaking
    if synthesizer.isSpeaking || synthesizer.isPaused {
      synthesizer.stopSpeaking(at: .immediate)
    }
    audioEngine.stop()
    playerNode.stop()
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
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    print(#function)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print(#function)

//     TODO: Migrate Cache
//    migrateCache()

    // NOTE: synthesizer.write 直後にも呼ばれるので、実際に終わった場合とsynthesizer.writeを区別する制御が必要
//      stopAudioComponents()
//      progress = nil
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    print(#function)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print(#function)

    stopAudioComponents()
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
//  private func writingAudioFileURL(targetArticleID: String) -> URL {
//    let tmpDir = URL(string: NSTemporaryDirectory())!
//    return tmpDir.appendingPathComponent("v1-writing-\(targetArticleID)")
//  }
//}
