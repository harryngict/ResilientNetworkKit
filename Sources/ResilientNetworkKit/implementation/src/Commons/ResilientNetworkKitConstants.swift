import Foundation

enum ResilientNetworkKitConstants {
  enum HTTPHeader: String, CaseIterable {
    case accept = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case contentType = "Content-Type"
    case requestId = "X-Request-ID"

    // MARK: Internal

    var value: String {
      switch self {
      case .accept:
        return "application/json"
      case .acceptEncoding:
        return "gzip, deflate"
      case .contentType:
        return "application/json"
      case .requestId:
        return UUID().uuidString
      }
    }
  }

  enum Message {
    static let noURL = "Unknown URL"
    static let noStatusCode = "Unknown Status Code"
    static let noHeadersSent = "Unknown number of HTTP headers sent"
    static let noHeadersReceived = "Unknown number of HTTP headers received"
  }

  static let loggingTag = "com.ResilientNetworkKit.Logging"
}
