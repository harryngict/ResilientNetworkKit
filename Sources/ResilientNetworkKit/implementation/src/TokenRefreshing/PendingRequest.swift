import Foundation
import ResilientNetworkKit

// MARK: - AnyPendingRequest

protocol AnyPendingRequest {
  func execute(networkKit: ResilientNetworkKit)
  func fail(with error: ResilientNetworkKitError)
}

// MARK: - AnyPendingRequestWrapper

struct AnyPendingRequestWrapper<E: Endpoint>: AnyPendingRequest {
  // MARK: Lifecycle

  init(endpoint: E,
       retry: RetryPolicy,
       networkTraceInspector: NetworkTraceInspector?,
       completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    self.endpoint = endpoint
    self.retry = retry
    self.networkTraceInspector = networkTraceInspector
    self.completion = completion
  }

  // MARK: Internal

  func execute(networkKit: ResilientNetworkKit) {
    networkKit.send(endpoint, retry: retry, completion: completion)
  }

  func fail(with error: ResilientNetworkKitError) {
    networkTraceInspector?.add(
      endpoint: endpoint,
      startTime: Date().millisecondsSince1970,
      endTime: Date().millisecondsSince1970,
      status: .finished,
      httpURLResponse: nil,
      data: nil,
      error: error)
    completion(.failure(error))
  }

  // MARK: Private

  private let endpoint: E
  private let retry: RetryPolicy
  private var networkTraceInspector: NetworkTraceInspector?
  private let completion: @Sendable (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void
}
