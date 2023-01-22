import Combine
import SwiftUI
import AVFoundation

final class Synthesizer: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.floatOrDefault(forKey: .synthesizerVolume)
  @Published var rate = UserDefaults.standard.floatOrDefault(forKey: .synthesizerRate)
  @Published var pitch = UserDefaults.standard.floatOrDefault(forKey: .synthesizerPitch)

  private let synthesizer = AVSpeechSynthesizer()
  private var progress: Progress?
  private var canceller: Set<AnyCancellable> = []

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: .synthesizerVolume)

        self?.updateSettingOnWrite()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: .synthesizerRate)

        self?.updateSettingOnWrite()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: .synthesizerPitch)

        self?.updateSettingOnWrite()
      }.store(in: &canceller)

    synthesizer.delegate = self
  }

  func writeToAudioFile(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch
    utterance.voice = .init(language: "ja-JP")

    synthesizer.write(utterance) { [weak self] buffer in
      guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
        return
      }
      if pcmBuffer.frameLength == 0 {
        return
      }

      // TODO: write
    }
  }
  
}

// MARK: - Private
private extension Synthesizer {
  func stop() {
    // NOTE: syntesizer is broken when call synthesizer.stopSpeaking when synthesizer is not speaking
    guard synthesizer.isSpeaking || synthesizer.isPaused else {
      return
    }
    synthesizer.stopSpeaking(at: .immediate)
  }

  private func updateSettingOnWrite() {
    // NOTE: 対象となる@Publishedなプロパティ(volume,rate,pitch)の更新はobjectWillChangeのタイミングで行われる。なので、更新後の値をプロパティアクセスからは取得できない。次のRunLoopで処理でプロパティアクセスするようにすることで更新後の値が取得できる
    DispatchQueue.main.async { [self] in
      // NOTE: 各関数の副作用の影響を受けないタイミングで、残りのテキストを一時変数に保持している
      let _remainingText = progress?.remainingText

      stop()

      if let remainingText = _remainingText {
        writeToAudioFile(text: remainingText)
      }
    }
  }
}

extension Synthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    print(#function)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print(#function)

    stop()
    progress = nil
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    print(#function)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print(#function)

    stop()
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
