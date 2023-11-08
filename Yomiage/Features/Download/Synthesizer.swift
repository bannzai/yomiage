import Combine
import SwiftUI
import AVFoundation

final class Synthesizer: NSObject, ObservableObject {
  @AppStorage(.synthesizerVolume) var volume: Double
  @AppStorage(.synthesizerRate) var rate: Double
  @AppStorage(.synthesizerPitch) var pitch: Double

  @Published var proceedPageURL: URL?
  @Published var finished: Void = ()

  private let synthesizer = AVSpeechSynthesizer()
  private var progress: Progress?
  private var canceller: Set<AnyCancellable> = []

  override init() {
    super.init()

    synthesizer.delegate = self
  }

  private func buildUtterance(string: String) -> AVSpeechUtterance {
//    let utterance = AVSpeechUtterance(ssmlRepresentation: string)!
    let utterance = AVSpeechUtterance(string: string)
    utterance.volume = Float(volume)
    utterance.rate = Float(rate)
    utterance.pitchMultiplier = Float(pitch)
    utterance.voice = .init(language: "ja-JP")
    return utterance
  }

  @MainActor func writeToAudioFile(body: String, pageURL: URL) async throws -> AVAudioFile {
    proceedPageURL = pageURL
    defer {
      proceedPageURL = nil
    }

    var writingAudioFile: AVAudioFile?
    do {
      let result = try await withCheckedThrowingContinuation { continuation in
        // NOTE: print(utterance.voice?.audioFileSettings) -> Optional(["AVNumberOfChannelsKey": 1, "AVLinearPCMIsFloatKey": 0, "AVLinearPCMIsNonInterleaved": 0, "AVSampleRateKey": 22050, "AVFormatIDKey": 1819304813, "AVLinearPCMIsBigEndianKey": 0, "AVLinearPCMBitDepthKey": 16])
        synthesizer.write(buildUtterance(string: body)) { buffer in
          print(#function, "#synthesizer.write")
          guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
            return
          }

          // Maybe did finish synthesizer.write
          if pcmBuffer.frameLength == 0 {
            if let writingAudioFile {
              continuation.resume(returning: writingAudioFile)
            } else {
              continuation.resume(throwing: NSError.synthesizerWriteFileNotFound)
            }
            return
          }

          do {
            if writingAudioFile == nil {
              writingAudioFile = try AVAudioFile(
                forWriting: AVAudioFile.filePath(for: pageURL),
                settings: pcmBuffer.format.settings,
                commonFormat: pcmBuffer.format.commonFormat,
                interleaved: false
              )
            }

            try writingAudioFile?.write(from: pcmBuffer)
          } catch {
            continuation.resume(throwing: error)
          }
        }
      }
      return result
    } catch {
      throw error
    }
  }

  func test() {
    let text = "これはテストです。このくらいの速さ。高さ。ボリュームで聞こえます"
    synthesizer.speak(buildUtterance(string: text))
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
}

extension Synthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    print(#function)
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
