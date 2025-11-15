import Foundation
import ResilientNetworkKit

open class BaseEncoded: RequestQueryEncodable {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func encodeParametersInHTTPBody(_ endpoint: some Endpoint,
                                       _ urlRequest: inout URLRequest) throws
  {
    /* abstract */
  }

  // MARK: Public

  public func encode(_ endpoint: some Endpoint, _ urlRequest: inout URLRequest) throws {
    if shouldEncodeParametersInURL(endpoint) {
      try encodeParametersInURL(endpoint, &urlRequest)
    } else {
      try encodeParametersInHTTPBody(endpoint, &urlRequest)
    }
  }

  // MARK: Private

  private func shouldEncodeParametersInURL(_ endpoint: some Endpoint) -> Bool {
    switch endpoint.method {
    case .get:
      return true
    case .delete,
         .head,
         .patch,
         .post,
         .put:
      return false
    }
  }

  private func encodeParametersInURL(_ endpoint: some Endpoint, _ urlRequest: inout URLRequest) throws {
    var components = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: true)
    var queryItems = [URLQueryItem]()
    for key in endpoint.query.keys.sorted() {
      if let value = endpoint.query[key] {
        if let itemArray = value as? [AnyHashable] {
          for item in itemArray {
            queryItems.append(URLQueryItem(name: key, value: "\(item)"))
          }
        } else {
          queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
      }
    }
    components?.queryItems = queryItems

    guard let url = components?.url else { throw ResilientNetworkKitError.invalidURL(url: endpoint.url.absoluteString) }

    urlRequest.url = url
  }
}
