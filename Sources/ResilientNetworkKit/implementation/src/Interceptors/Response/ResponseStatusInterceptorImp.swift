import Foundation
import ResilientNetworkKit

open class ResponseStatusInterceptorImp: @unchecked Sendable, ResponseStatusInterceptor {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func intercept(_ response: HTTPURLResponse,
                      endpoint: some Endpoint)
    -> StatusCode
  {
    StatusCode(code: response.statusCode)
  }
}
