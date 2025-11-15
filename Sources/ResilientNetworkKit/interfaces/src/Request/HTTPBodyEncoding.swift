import Foundation

// MARK: - HTTPBodyEncoding

@frozen
public enum HTTPBodyEncoding {
  case urlencoded
  case json
  case custom(RequestQueryEncodable)
}

// MARK: - RequestQueryEncodable

public protocol RequestQueryEncodable {
  func encode(_ endpoint: some Endpoint, _ urlRequest: inout URLRequest) throws
}
