import Foundation
import ResilientNetworkKit

class ResilientNetworkKitDecorator: ResilientNetworkKit, @unchecked Sendable {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit, networkLogTracker: NetworkLogTracker) {
    self.networkKit = networkKit
    self.networkLogTracker = networkLogTracker
  }

  // MARK: Internal

  let networkKit: ResilientNetworkKit
  let networkLogTracker: NetworkLogTracker

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType) async throws
    -> (E.Response, Int, ResilientNetworkKitHeaders)
  {
    try await withCheckedThrowingContinuation { continuation in
      send(endpoint, retry: retry, receiveOn: queue) { result in
        switch result {
        case let .success(response): continuation.resume(returning: response)
        case let .failure(error): continuation.resume(throwing: error)
        }
      }
    }
  }

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType,
                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    Task {
      if let shouldAbort = await preSend(endpoint, retry: retry, queue: queue, completion: completion) {
        if shouldAbort { return }
      }

      networkKit.send(endpoint, retry: retry, receiveOn: queue) { [weak self] result in
        guard let self else { return }
        switch result {
        case let .success(response):
          self.postSuccess(endpoint, response: response)
          completion(.success(response))
        case let .failure(error):
          self.postFailure(endpoint, error: error, retry: retry, queue: queue, completion: completion)
        }
      }
    }
  }

  @Sendable
  func cancelAllRequest(completingOn queue: DispatchQueueType, completion: (@Sendable () -> Void)?) {
    networkKit.cancelAllRequest(completingOn: queue, completion: completion)
  }

  // MARK: - Hooks (Override in subclasses)

  func preSend<E: Endpoint>(_ endpoint: E,
                            retry: RetryPolicy,
                            queue: DispatchQueueType,
                            completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void) async
    -> Bool? { nil }

  func postSuccess<E: Endpoint>(_ endpoint: E, response: (E.Response, Int, ResilientNetworkKitHeaders)) {}

  func postFailure<E: Endpoint>(_ endpoint: E,
                                error: ResilientNetworkKitError,
                                retry: RetryPolicy,
                                queue: DispatchQueueType,
                                completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void) {}
}
