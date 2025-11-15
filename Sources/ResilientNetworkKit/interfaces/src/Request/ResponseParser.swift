import Foundation

// MARK: - ResponseParser

/// @mockable
public protocol ResponseParser {
  func parse<T: Decodable>(data: Data) throws -> T
}

// MARK: - DefaultResponseParser

public final class DefaultResponseParser: ResponseParser {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public func parse<T>(data: Data) throws -> T where T: Decodable {
    if T.self == Data.self {
      guard let value = data as? T else {
        throw ResilientNetworkKitError.dataFoundNil
      }
      return value
    } else if T.self == String.self {
      guard let value = String(data: data, encoding: .utf8) as? T else {
        throw StringParserStrategyError.unableToConvertDataToString
      }
      return value
    } else {
      let value: T
      do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        value = try decoder.decode(T.self, from: data)
      } catch {
        throw ResilientNetworkKitError.decodingFailed(type: T.self, error: error)
      }

      return value
    }
  }
}

// MARK: - StringParserStrategyError

public enum StringParserStrategyError: Error {
  case unableToConvertDataToString
}

// MARK: - AccountResponse

public struct AccountResponse: Decodable {
  public let id: Int
  public let name: String
}
