import Foundation
import ResilientNetworkKit

// MARK: - JSONEncoded Implementation

public final class JSONEncoded: BaseEncoded {
  // MARK: Lifecycle

  override public init() {
    super.init()
  }

  // MARK: Public

  override public func encodeParametersInHTTPBody(_ endpoint: some Endpoint,
                                                  _ urlRequest: inout URLRequest) throws
  {
    let httpBody = try JSONSerialization.data(withJSONObject: endpoint.query)
    if urlRequest.allHTTPHeaderFields?[Constants.contentTypeField] == nil {
      urlRequest.setValue(Constants.json, forHTTPHeaderField: Constants.contentTypeField)
    }
    urlRequest.httpBody = httpBody
  }

  // MARK: Private

  private enum Constants {
    static let contentTypeField = "Content-Type"
    static let json = "application/json; charset=utf-8"
  }
}
