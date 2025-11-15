import Foundation
import ResilientNetworkKit

// MARK: - TokenRefreshState

actor TokenRefreshState: Sendable {
  private var tokenRefreshTask: Task<Void, Never>?
  private var pendingRequests: [AnyPendingRequest] = []
  private let tokenRefreshingInterceptor: TokenRefreshingInterceptor

  init(tokenRefreshingInterceptor: TokenRefreshingInterceptor) {
    self.tokenRefreshingInterceptor = tokenRefreshingInterceptor
  }

  var isRefreshing: Bool {
    tokenRefreshTask != nil
  }

  func addToQueue<E: Endpoint>(endpoint: E,
                               retry: RetryPolicy,
                               networkTraceInspector: NetworkTraceInspector?,
                               completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    let requestWrapper = AnyPendingRequestWrapper(
      endpoint: endpoint,
      retry: retry,
      networkTraceInspector: networkTraceInspector,
      completion: completion)

    pendingRequests.append(requestWrapper)
  }

  func handleRequestFailure<E: Endpoint>(
    error: ResilientNetworkKitError,
    endpoint: E,
    retry: RetryPolicy,
    networkKit: ResilientNetworkKit,
    networkTraceInspector: NetworkTraceInspector?,
    completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void) async
  {
    guard isTokenExpired(error) else {
      completion(.failure(error))
      return
    }
    addToQueue(endpoint: endpoint, retry: retry, networkTraceInspector: networkTraceInspector, completion: completion)

    if let task = tokenRefreshTask {
      await task.value
      executePendingRequests(networkKit: networkKit)
      return
    }

    let task = Task {
      defer { tokenRefreshTask = nil }
      do {
        try await tokenRefreshingInterceptor.refreshAccessTokenAsync()
        executePendingRequests(networkKit: networkKit)
      } catch {
        failPendingRequests(with: .networkError(error: error))
      }
    }

    tokenRefreshTask = task
    await task.value
  }

  private func clearTask() {
    tokenRefreshTask = nil
  }

  private func executePendingRequests(networkKit: ResilientNetworkKit) {
    for request in pendingRequests {
      request.execute(networkKit: networkKit)
    }
    pendingRequests.removeAll()
  }

  private func failPendingRequests(with error: ResilientNetworkKitError) {
    for request in pendingRequests {
      request.fail(with: error)
    }
    pendingRequests.removeAll()
  }

  private func isTokenExpired(_ error: ResilientNetworkKitError) -> Bool {
    guard StatusCode(code: error.statusCode ?? -1) == .unauthorised else { return false }
    return true
  }
}
