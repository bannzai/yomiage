import Combine
import SwiftUI
import AVFoundation

final class Synthesizer: NSObject, ObservableObject {
  @AppStorage(.synthesizerVolume) var volume: Double
  @AppStorage(.synthesizerRate) var rate: Double
  @AppStorage(.synthesizerPitch) var pitch: Double

  @Published var proceedPageURL: URL?
  @Published var error: Error?
  @Published var finished: Void = ()
  var isLoading: Bool {
    proceedPageURL != nil
  }

  private let synthesizer = AVSpeechSynthesizer()
  private var progress: Progress?
  private var canceller: Set<AnyCancellable> = []
  private var writingAudioFile: AVAudioFile?

  func writeToAudioFile(body: String, pageURL: URL) {
    proceedPageURL = pageURL

    let utterance = AVSpeechUtterance(string: body)
    // NOTE: AppStorage does not support `Float`
    utterance.volume = Float(volume)
    utterance.rate = Float(rate)
    utterance.pitchMultiplier = Float(pitch)
    utterance.voice = .init(language: "ja-JP")

    synthesizer.write(utterance) { [weak self] buffer in
      guard let pcmBuffer = buffer as? AVAudioPCMBuffer, pcmBuffer.frameLength > 0 else {
        return
      }
      guard let self else {
        return
      }
      do {
        if self.writingAudioFile == nil {
          self.writingAudioFile = try AVAudioFile(forWriting: self.writingAudioFileURL(url: pageURL), settings: pcmBuffer.format.settings, commonFormat: .pcmFormatInt16, interleaved: false)
        }
        try self.writingAudioFile?.write(from: pcmBuffer)
      } catch {
        self.error = error
      }
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

  func writingAudioFileURL(url: URL) -> URL {
    let tmpDir = URL(string: NSTemporaryDirectory())!
    return tmpDir
      .appendingPathComponent("v1")
      .appendingPathComponent(url.path(percentEncoded: false))
  }
}

extension Synthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    print(#function)
    error = nil
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print(#function)

    stop()
    proceedPageURL = nil
    progress = nil
    finished = ()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    print(#function)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print(#function)

    stop()
    proceedPageURL = nil
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
