import Foundation
import ResilientNetworkKit

final class AdvancedRetryNetworkKit: ResilientNetworkKitDecorator, @unchecked Sendable {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit,
       advancedRetryInterceptor: AdvancedRetryInterceptor,
       networkLogTracker: NetworkLogTracker)
  {
    self.advancedRetryInterceptor = advancedRetryInterceptor
    super.init(networkKit: networkKit, networkLogTracker: networkLogTracker)
  }

  // MARK: Internal

  override func postFailure<E: Endpoint>(_ endpoint: E,
                                         error: ResilientNetworkKitError,
                                         retry: RetryPolicy,
                                         queue: DispatchQueueType,
                                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    guard let advancedPolicy = advancedRetryInterceptor.getRetryPolicy(endpoint, error: error) else {
      completion(.failure(error))
      return
    }
    networkLogTracker.infor(
      ResilientNetworkKitConstants.loggingTag,
      "Advanced retry policy applied with retryCount: \(advancedPolicy.retryCount)")
    networkKit.send(endpoint, retry: advancedPolicy, receiveOn: queue, completion: completion)
  }

  // MARK: Private

  private let advancedRetryInterceptor: AdvancedRetryInterceptor
}
