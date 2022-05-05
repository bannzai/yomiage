import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  @Published private(set) var loadingArticle: Article?
  let loadedBody = PassthroughSubject<String, Never>()
  @Published private(set) var playingArticle: Article?

  var allArticle: Set<Article> = []
  @Published var localizedError: Error?

  private let synthesizer = AVSpeechSynthesizer()
  private var canceller: Set<AnyCancellable> = []
  private var cachedFullText: [Article: String] = [:]
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

  private var webViewReference: WebView<Player>?
  func load(article: Article) {
    loadingArticle = article

    webViewReference = .init(url: URL(string: article.pageURL)!, loader: self)
  }

  func speak(article: Article, title: String, text: String) {
    playingArticle = article
    cachedFullText[article] = text

    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: rate
    ]

    speak(text: text)
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
    MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { event in
      guard
        let playingArticle = self.playingArticle,
        let nextArticleIndex = self.allArticle.firstIndex(of: playingArticle) else {
        return .commandFailed
      }

      let nextArticle = self.allArticle[nextArticleIndex]
      if let nextBody = self.cachedFullText[nextArticle] {
        if let note = nextArticle.note {
          self.speak(article: nextArticle, title: note.title, text: nextBody)
        } else if let medium = nextArticle.medium {
          self.speak(article: nextArticle, title: medium.title, text: nextBody)
        } else {
          return .commandFailed
        }
        return .success
      } else {
        self.loadingArticle = nextArticle
        return .success
      }
    }
  }

  // MARK: - Private
  private func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    synthesizer.speak(utterance)
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

extension Player: LoadHTMLLoader {
  func javaScript() -> String? {
    guard let article = loadingArticle else {
      return nil
    }

    switch article.typedKind {
    case .note:
      return """
const bodyDocument = document.getElementsByClassName('note-common-styles__textnote-body')[0];
const body = Array.from(bodyDocument.children).reduce((previousValue, element) => {
  if (['h1', 'h2', 'h3', 'h4'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n' + '\\n';
  } else if (['p', 'ul'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n';
  } else {
    return previousValue + element.textContent;
  }
},'');
body;
"""
    case .medium:
      return """
const bodyDocument = document.querySelector("article").querySelector("section");
const body = Array.from(bodyDocument.children).reduce((previousValue, element) => {
  if (['h1', 'h2', 'h3', 'h4'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n' + '\\n';
  } else if (['p', 'ul'].includes(element.localName)) {
    return previousValue + '\\n' + element.textContent + '\\n';
  } else {
    return previousValue + element.textContent;
  }
},'');
body;
"""
    case nil:
      return nil
    }
  }

  func handlEevaluateJavaScript(arguments: (Any?, Error?)) {
    guard let loadingArticle = loadingArticle else {
      return
    }
    defer {
      self.loadingArticle = nil
    }

    print("arguments: \(arguments)")
    if let html = arguments.0 as? String {
      cachedFullText[loadingArticle] = html
      loadedBody.send(html)
    } else if let loadError = arguments.1 {
      localizedError = WebViewLoadHTMLError(error: loadError)
    } else {
      localizedError = WebViewLoadHTMLError(error: nil)
    }
  }
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


fileprivate struct WebViewLoadHTMLError: LocalizedError {
  let error: Error?

  var errorDescription: String? {
    "読み込みに失敗しました"
  }
  var failureReason: String? {
    (error as? LocalizedError)?.failureReason ?? "通信環境をお確かめの上再度実行してください"
  }
  let helpAnchor: String? = nil
  let recoverySuggestion: String? = nil
}
