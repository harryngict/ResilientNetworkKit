import Foundation
import ResilientNetworkKit

final class AdvancedRetryInterceptorImp: AdvancedRetryInterceptor {
  // MARK: Lifecycle

  init() {}

  // MARK: Internal

  func getRetryPolicy(_ endPoint: some Endpoint, error: ResilientNetworkKitError) -> RetryPolicy? {
    guard [503, 504].first(where: { $0 == error.statusCode }) != nil else { return nil }
    return RetryPolicy.constant(count: 5, delay: 5.0)
  }
}
