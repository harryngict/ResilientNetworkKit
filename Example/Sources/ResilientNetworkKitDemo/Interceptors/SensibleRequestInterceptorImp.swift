
import Foundation
import ResilientNetworkKit

final class SensibleRequestInterceptorImp: RequestInterceptor {
  // MARK: Lifecycle

  init() {}

  // MARK: Internal

  func modify<E: Endpoint>(endpoint: E) -> E {
    endpoint
  }
}
