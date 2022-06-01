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

  var engine = AVAudioEngine()
  var player = AVAudioPlayerNode()
  var eqEffect = AVAudioUnitEQ()
  var converter = AVAudioConverter(from: AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: false)!, to: AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!)
  let synthesizer = AVSpeechSynthesizer()
  var bufferCounter: Int = 0

  let audioSession = AVAudioSession.sharedInstance()
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

    let outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)!
    setupAudio(format: outputFormat, globalGain: 0)

    if let cachedPCMBuffer = readPCMBuffer(url: fileURL) {

    } else {
      synthesizer.write(utterance) { [weak self] buffer in
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
          return
        }
        if pcmBuffer.frameLength == 0 {
          return
        }

        do {
          let file = try AVAudioFile(forWriting: fileURL, settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
          try file.write(from: pcmBuffer)
          self?.play(audioFile: file)
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
  }


  func activateAudioSession() {
    do {
      try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("An error has occurred while setting the AVAudioSession.")
    }
  }
  func play(audioFile file: AVAudioFile) {
    self.player.scheduleFile(file, at: nil, completionHandler: nil)
    let utterance = AVSpeechUtterance(string: "This is to test if iOS is able to boost the voice output above the 100% limit.")
    synthesizer.write(utterance) { buffer in
      guard let pcmBuffer = buffer as? AVAudioPCMBuffer, pcmBuffer.frameLength > 0 else {
        print("could not create buffer or buffer empty")
        return
      }

      // QUIRCK Need to convert the buffer to different format because AVAudioEngine does not support the format returned from AVSpeechSynthesizer
      let convertedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: pcmBuffer.format.sampleRate, channels: pcmBuffer.format.channelCount, interleaved: false)!, frameCapacity: pcmBuffer.frameCapacity)!
      do {
        try self.converter!.convert(to: convertedBuffer, from: pcmBuffer)
        self.bufferCounter += 1
        self.player.scheduleBuffer(convertedBuffer, completionCallbackType: .dataPlayedBack, completionHandler: { (type) -> Void in
          DispatchQueue.main.async {
            self.bufferCounter -= 1
            print(self.bufferCounter)
            if self.bufferCounter == 0 {
              self.player.stop()
              self.engine.stop()
              try! self.audioSession.setActive(false, options: [])
            }
          }

        })

        self.converter!.reset()
        //self.player.prepare(withFrameCount: convertedBuffer.frameLength)
      }
      catch let error {
        print(error.localizedDescription)
      }
    }
    activateAudioSession()
    if !self.engine.isRunning {
      try! self.engine.start()
    }
    if !self.player.isPlaying {
      self.player.play()
    }
  }

  func setupAudio(format: AVAudioFormat, globalGain: Float) {
    // QUIRCK: Connecting the equalizer to the engine somehow starts the shared audioSession, and if that audiosession is not configured with .mixWithOthers and if it's not deactivated afterwards, this will stop any background music that was already playing. So first configure the audio session, then setup the engine and then deactivate the session again.
    try? self.audioSession.setCategory(.playback, options: .mixWithOthers)

    eqEffect.globalGain = globalGain
    engine.attach(player)
    engine.attach(eqEffect)
    engine.connect(player, to: eqEffect, format: format)
    engine.connect(eqEffect, to: engine.mainMixerNode, format: format)
    engine.prepare()

    try? self.audioSession.setActive(false)

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
