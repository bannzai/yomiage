import Combine
import SwiftUI

final class Synthesizer: ObservableObject {
  @AppStorage(.volume) var volume: Float
  @AppStorage(.rate) var rate: Float
  @AppStorage(.pitch) var pitch: Float

  func writeToAudioFile() {

  }
}
