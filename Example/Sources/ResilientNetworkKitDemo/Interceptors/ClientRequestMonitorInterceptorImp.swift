import Foundation
import ResilientNetworkKit
import ResilientNetworkKitImp

final class ClientRequestInterceptorImp: RequestInterceptor {
  // MARK: Lifecycle

  init() {}

  // MARK: Internal

  func modify<E>(endpoint: E) -> E where E: Endpoint {
    endpoint
  }
}
