import Foundation
import ResilientNetworkKit

final class CircuitBreakerNetworkKit: ResilientNetworkKitDecorator, @unchecked Sendable {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit,
       configuration: CircuitBreakerConfiguration,
       networkLogTracker: NetworkLogTracker,
       networkTraceInspector: NetworkTraceInspector?)
  {
    circuitBreaker = CircuitBreaker(configuration: configuration)
    self.networkTraceInspector = networkTraceInspector
    super.init(networkKit: networkKit, networkLogTracker: networkLogTracker)
  }

  // MARK: Internal

  override func preSend<E: Endpoint>(_ endpoint: E,
                                     retry: RetryPolicy,
                                     queue: DispatchQueueType,
                                     completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void) async
    -> Bool?
  {
    guard circuitBreaker.shouldAllowRequest() else {
      networkLogTracker.error(ResilientNetworkKitConstants.loggingTag, "Circuit breaker open.")
      networkTraceInspector?.add(
        endpoint: endpoint,
        startTime: Date().millisecondsSince1970,
        endTime: Date().millisecondsSince1970,
        status: .finished,
        httpURLResponse: nil,
        data: nil,
        error: .circuitBreakerOpen)
      queue.async { completion(.failure(.circuitBreakerOpen)) }
      return true
    }
    return false
  }

  override func postSuccess<E: Endpoint>(_ endpoint: E, response: (E.Response, Int, ResilientNetworkKitHeaders)) {
    circuitBreaker.reportSuccess()
  }

  override func postFailure<E: Endpoint>(_ endpoint: E,
                                         error: ResilientNetworkKitError,
                                         retry: RetryPolicy,
                                         queue: DispatchQueueType,
                                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    circuitBreaker.reportFailure(error: error)
    completion(.failure(error))
  }

  // MARK: Private

  private let circuitBreaker: CircuitBreaker
  private let networkTraceInspector: NetworkTraceInspector?
}
