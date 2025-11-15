import Foundation

// MARK: - ResilientNetworkKit

/// @mockable
public protocol ResilientNetworkKit: Sendable {
  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType) async throws
    -> (E.Response, Int, ResilientNetworkKitHeaders)

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType,
                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)

  @Sendable
  func cancelAllRequest(completingOn queue: DispatchQueueType, completion: (@Sendable () -> Void)?)
}

public extension ResilientNetworkKit {
  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy = .none,
                         receiveOn queue: DispatchQueueType = DispatchQueue.main) async throws
    -> (E.Response, Int, ResilientNetworkKitHeaders)
  {
    try await send(endpoint, retry: retry, receiveOn: queue)
  }

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy = .none,
                         receiveOn queue: DispatchQueueType = DispatchQueue.main,
                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    send(endpoint, retry: retry, receiveOn: queue, completion: completion)
  }
}

public struct ResilientNetworkKitHeaders: @unchecked Sendable {
  // MARK: Lifecycle

  public init(headers: [AnyHashable: any Sendable]) {
    self.headers = headers
  }

  // MARK: Public

  public subscript(key: AnyHashable) -> (any Sendable)? {
    headers[key]
  }

  // MARK: Internal

  let headers: [AnyHashable: any Sendable]
}
