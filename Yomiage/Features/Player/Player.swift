import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  @Published private(set) var playingArticle: Article?

  var allArticle: Set<Article> = []
  @Published var error: Error?

  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let outputAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
  private let synthesizer = AVSpeechSynthesizer()
  
  private var canceller: Set<AnyCancellable> = []
  private var progress: Progress?

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)

        self?.reset()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)

        self?.reset()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)

        self?.reset()
      }.store(in: &canceller)

    synthesizer.delegate = self

    audioEngine.attach(playerNode)
    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputAudioFormat)
    audioEngine.prepare()
  }

  @MainActor func play(article: Article, url: URL, kind: Article.Kind) async {

    do {
      let body: String
      switch kind {
      case .note:
        body = try await loadNoteBody(url: url)
      case .medium:
        body = try await loadMediumBody(url: url)
      }

      playingArticle = article
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
  }

  func stop() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    playingArticle = nil
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
  }

  // MARK: - Private
  private func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    // TODO: Pass from argument
    let playingArticleID = playingArticle!.id!
    let fileURL = URL(string: "file:///tmp/\(playingArticleID)")!

    synthesizer.write(utterance) { [weak self] buffer in
      print("in synthesizer.write(utterance)")
      guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
        return
      }
      if pcmBuffer.frameLength == 0 {
        return
      }

      do {
        //          let file = try AVAudioFile(forWriting: fileURL, settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
        //          try file.write(from: pcmBuffer)
        self?.play(pcmBuffer: pcmBuffer)
      } catch {
        fatalError(error.localizedDescription)
      }


      // Cache to file systems
      //        do {
      //          let file = try AVAudioFile(forWriting: fileURL, settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
      //          try file.write(from: pcmBuffer)
      //        } catch { }
    }
  }


  // Ref: https://stackoverflow.com/questions/56999334/boost-increase-volume-of-text-to-speech-avspeechutterance-to-make-it-louder
  private func play(pcmBuffer: AVAudioPCMBuffer) {

    // NOTE: PCM format is pcmFormatInt16
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

    playerNode.scheduleBuffer(convertedBuffer, at: nil)

    do {
      try audioEngine.start()
    } catch {
      fatalError(error.localizedDescription)
    }
    playerNode.play()
  }

  private func readPCMBuffer(url: URL) -> AVAudioPCMBuffer? {
    guard let input = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false) else {
      return nil
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)) else {
      return nil
    }
    do {
      try input.read(into: buffer)
    } catch {
      return nil
    }

    return buffer
  }

  private func reset() {
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

    progress = nil
    playingArticle = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
