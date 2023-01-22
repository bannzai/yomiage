import Combine
import SwiftUI
import AVFoundation

final class Synthesizer: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.floatOrDefault(forKey: .synthesizerVolume)
  @Published var rate = UserDefaults.standard.floatOrDefault(forKey: .synthesizerRate)
  @Published var pitch = UserDefaults.standard.floatOrDefault(forKey: .synthesizerPitch)

  private var canceller: Set<AnyCancellable> = []

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: .synthesizerVolume)

        //        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: .synthesizerRate)
//        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: .synthesizerPitch)
//        self?.reloadWhenUpdatedPlayerSetting()
      }.store(in: &canceller)

//    synthesizer.delegate = self
//    resetAudioEngine()
//    setupRemoteTransportControls()
  }

  func writeToAudioFile(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch
    utterance.voice = .init(language: "ja-JP")

//    synthesizer.write(utterance) { [weak self] buffer in
//      self?.synthesizerIsWriting.send(true)
//      guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
//        return
//      }
//      if pcmBuffer.frameLength == 0 {
//        return
//      }
//      // TODO: write
//    }
  }
}
