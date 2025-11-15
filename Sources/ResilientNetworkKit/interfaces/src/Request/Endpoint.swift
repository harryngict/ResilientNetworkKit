import Foundation

// MARK: - Endpoint

public protocol Endpoint: Hashable, CustomStringConvertible, Identifiable, Sendable {
  associatedtype Response: Decodable & Sendable
  var id: String { get }
  var url: URL { get }
  var method: HTTPMethod { get }
  var query: [String: AnyHashable] { get set }
  var headers: [String: String] { get set }
  var httpBodyEncoding: HTTPBodyEncoding { get }

  var priority: Float { get }
  var timeout: TimeInterval { get }
  var cachePolicy: URLRequest.CachePolicy { get }
  var responseParser: ResponseParser { get }
  var isRefreshTokenEndpoint: Bool { get }
}

public extension Endpoint {
  var httpBodyEncoding: HTTPBodyEncoding { .json }
  var priority: Float { 0.5 }
  var timeout: TimeInterval { 60 }
  var cachePolicy: URLRequest.CachePolicy { .useProtocolCachePolicy }
  var responseParser: ResponseParser { DefaultResponseParser() }
  var isRefreshTokenEndpoint: Bool { false }

  var description: String {
    """
    Endpoint:
    - URL: \(url)
    - Method: \(method)
    - Query: \(query)
    - Headers: \(headers)
    - HTTP Body Encoding: \(httpBodyEncoding)
    - Priority: \(priority)
    - Timeout: \(timeout)
    - Cache Policy: \(cachePolicy)
    - Response Parser: \(responseParser)
    """
  }

  var id: String {
    "\(method.rawValue)-\(url.absoluteString)"
  }
}

public extension Endpoint {
  func hash(into hasher: inout Hasher) {
    hasher.combine(url)
    hasher.combine(method)
    hasher.combine(query)
    hasher.combine(headers)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.url == rhs.url &&
      lhs.method == rhs.method &&
      lhs.headers == rhs.headers &&
      lhs.query == rhs.query
  }
}
