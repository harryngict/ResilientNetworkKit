import Foundation
import ResilientNetworkKit

typealias URLSessionTaskResult = (data: Data?, response: URLResponse?, error: Error?)

// MARK: - ResponseInterceptingPipeline

/// @mockable
protocol ResponseInterceptingPipeline: ResponseDataIntercepting & ResponseErrorIntercepting & ResponseStatusIntercepting {}

// MARK: - ResponseErrorIntercepting

/// @mockable
protocol ResponseErrorIntercepting: Sendable {
  func interceptError(_ error: Error?, endpoint: some Endpoint) throws -> ResponseStatusIntercepting
}

// MARK: - ResponseStatusIntercepting

/// @mockable
protocol ResponseStatusIntercepting: Sendable {
  func interceptStatus(result: URLSessionTaskResult,
                       request: URLRequest,
                       endpoint: some Endpoint,
                       requestStartTime: TimeInterval,
                       requestEndTime: TimeInterval) throws
    -> ResponseDataIntercepting
}

// MARK: - ResponseDataIntercepting

/// @mockable
protocol ResponseDataIntercepting: Sendable {
  func interceptData<E: Endpoint>(_ data: Data?, endpoint: E) throws -> E.Response
}
