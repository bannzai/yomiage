import Foundation

private let endpoint = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"

struct TTS {
  private init() { }
  static let shared = TTS()

  func request(text: String, voice: (name: String, languageCode: String)) async throws -> Data {
    let json: [String: Any] = [
      "input": [
        "text": text
      ],
      "voice": [
        "name": voice.name,
        "languageCode": voice.languageCode,
      ],
      "audioConfig": [
        "audioEncoding": "LINEAR16"
      ]
    ]
    let httpBody = try! JSONSerialization.data(withJSONObject: json)

    var urlRequest = URLRequest(url: .init(string: endpoint)!)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = httpBody
    urlRequest.addValue(Secret.googleTextToSpeechAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
    urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

    let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
    guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
      fatalError()
    }
    guard (200..<300) ~= httpURLResponse.statusCode else {
      throw TTSError.invalidHTTPResponseStatusCode(statusCode: httpURLResponse.statusCode)
    }

    let response = try JSONDecoder().decode(Response.self, from: data)
    guard let audio = Data(base64Encoded: response.audioContent) else {
      throw TTSError.audioContentDecodeFailed
    }

    return audio
  }

  struct Response: Codable {
    let audioContent: String
  }

  enum TTSError: LocalizedError {
    case invalidHTTPResponseStatusCode(statusCode: Int)
    case audioContentDecodeFailed

    var errorDescription: String? {
      switch self {
      case .invalidHTTPResponseStatusCode:
        return "通信時にエラーが発生しました"
      case .audioContentDecodeFailed:
        return "音声化に失敗しました"
      }
    }

    var failureReason: String? {
      switch self {
      case let .invalidHTTPResponseStatusCode(statusCode):
        return """
ステータスコード: \(statusCode)
通信環境をお確かめください
"""
      case .audioContentDecodeFailed:
        return """
解決しない場合は アプリトップ画面左上の ⓘ ボタンよりエラーが出たURLと共にご報告ください
"""
      }
    }
  }
}
