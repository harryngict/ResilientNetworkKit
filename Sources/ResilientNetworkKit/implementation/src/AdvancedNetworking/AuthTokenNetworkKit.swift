import Foundation
import ResilientNetworkKit

final class AuthTokenNetworkKit: ResilientNetworkKitDecorator, @unchecked Sendable {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit,
       tokenRefreshingInterceptor: TokenRefreshingInterceptor,
       networkLogTracker: NetworkLogTracker,
       networkTraceInspector: NetworkTraceInspector?)
  {
    tokenRefreshState = TokenRefreshState(tokenRefreshingInterceptor: tokenRefreshingInterceptor)
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
    if await tokenRefreshState.isRefreshing, !endpoint.isRefreshTokenEndpoint {
      networkLogTracker.infor(ResilientNetworkKitConstants.loggingTag, "Refreshing token, queueing endpoint \(endpoint)")
      await tokenRefreshState.addToQueue(endpoint: endpoint, retry: retry, networkTraceInspector: networkTraceInspector, completion: completion)
      return true
    }
    return false
  }

  override func postFailure<E: Endpoint>(_ endpoint: E,
                                         error: ResilientNetworkKitError,
                                         retry: RetryPolicy,
                                         queue: DispatchQueueType,
                                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    Task {
      await tokenRefreshState.handleRequestFailure(
        error: error,
        endpoint: endpoint,
        retry: retry,
        networkKit: networkKit,
        networkTraceInspector: networkTraceInspector,
        completion: completion)
    }
  }

  // MARK: Private

  private let tokenRefreshState: TokenRefreshState
  private let networkTraceInspector: NetworkTraceInspector?
}
