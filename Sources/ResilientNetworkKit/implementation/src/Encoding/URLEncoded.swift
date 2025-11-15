import Foundation
import ResilientNetworkKit

// MARK: - URLEncoded

public final class URLEncoded: BaseEncoded {
  // MARK: Lifecycle

  override public init() {
    super.init()
  }

  // MARK: Public

  override public func encodeParametersInHTTPBody(_ endpoint: some Endpoint,
                                                  _ urlRequest: inout URLRequest) throws
  {
    if urlRequest.allHTTPHeaderFields?[Constants.contentTypeField] == nil {
      urlRequest.setValue(Constants.urlEncoded, forHTTPHeaderField: Constants.contentTypeField)
    }

    let encodedUTF8String = query(endpoint.query).utf8
    urlRequest.httpBody = Data(encodedUTF8String)
  }

  // MARK: Private

  private enum Constants {
    static let contentTypeField = "Content-Type"
    static let urlEncoded = "application/x-www-form-urlencoded; charset=utf-8"
    static let urlEncodedSeparator = "&"
  }

  private func query(_ parameters: [String: Any]) -> String {
    var components: [(String, String)] = []

    for key in parameters.keys.sorted(by: <) {
      components += queryComponents(fromKey: key, value: parameters[key]!)
    }

    return components.map { "\($0)=\($1)" }.joined(separator: Constants.urlEncodedSeparator)
  }

  private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
    var components: [(String, String)] = []
    switch value {
    case let dictionary as [String: Any]:
      for item in dictionary {
        components += queryComponents(fromKey: "\(key)[\(item.key)]", value: item.value)
      }
    case let array as [Any]:
      for item in array {
        components += queryComponents(fromKey: "\(key)[]", value: item)
      }
    case let boolean as Bool:
      components.append((key.escaped, boolean.encoded.escaped))
    default:
      components.append((key.escaped, "\(value)".escaped))
    }
    return components
  }
}

// MARK: - Helper extensions (private)

extension String {
  var escaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
  }
}

extension Bool {
  var encoded: String {
    self ? "1" : "0"
  }
}
