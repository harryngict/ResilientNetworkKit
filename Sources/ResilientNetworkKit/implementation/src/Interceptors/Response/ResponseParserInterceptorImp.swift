import Foundation
import ResilientNetworkKit

open class ResponseParserInterceptorImp: @unchecked Sendable, ResponseParserInterceptor {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func intercept<E: Endpoint>(_ data: Data?, endpoint: E) throws -> E.Response {
    guard let data else {
      throw ResilientNetworkKitError.dataFoundNil
    }
    return try endpoint.responseParser.parse(data: data)
  }
}
