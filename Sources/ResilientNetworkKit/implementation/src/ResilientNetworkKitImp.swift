import Foundation
import ResilientNetworkKit

// MARK: - ResilientNetworkKitImp

final class ResilientNetworkKitImp: ResilientNetworkKit {
  // MARK: Lifecycle

  init(session: NetworkKitSession,
       requestInterceptors: [RequestInterceptor],
       responsePipeline: ResponseInterceptingPipeline,
       networkTraceInspector: NetworkTraceInspector?,
       retryDispatchQueue: DispatchQueueType = DispatchQueue.global())
  {
    self.session = session
    self.requestInterceptors = requestInterceptors
    self.responsePipeline = responsePipeline
    self.networkTraceInspector = networkTraceInspector
    self.retryDispatchQueue = retryDispatchQueue
  }

  // MARK: Internal

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType) async throws
    -> (E.Response, Int, ResilientNetworkKitHeaders)
  {
    try await withCheckedThrowingContinuation { continuation in
      send(endpoint, retry: retry, receiveOn: queue) { result in
        continuation.resume(with: result)
      }
    }
  }

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType,
                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    let requestStartTime = Date().millisecondsSince1970
    tracePending(endpoint, startTime: requestStartTime)

    let mutateEndpoint = mutate(endpoint: endpoint)
    performRequest(
      currentRetry: 0,
      endpoint: mutateEndpoint,
      retry: retry,
      receiveOn: queue,
      requestStartTime: requestStartTime,
      completion: completion)
  }

  @Sendable
  func cancelAllRequest(completingOn queue: DispatchQueueType,
                        completion: (@Sendable () -> Void)?)
  {
    session.getAllTasks { tasks in
      tasks.forEach { $0.cancel() }
      queue.async { completion?() }
    }
  }

  // MARK: Private

  private let session: NetworkKitSession
  private let requestInterceptors: [RequestInterceptor]
  private let responsePipeline: ResponseInterceptingPipeline
  private let networkTraceInspector: NetworkTraceInspector?
  private let retryDispatchQueue: DispatchQueueType

  private func performRequest<E: Endpoint>(currentRetry: Int,
                                           endpoint: E,
                                           retry: RetryPolicy,
                                           receiveOn queue: DispatchQueueType,
                                           requestStartTime: TimeInterval,
                                           completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    do {
      let urlRequest = try makeURLRequest(with: endpoint)
      let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
        guard let self else { return }
        do {
          let requestEndTime = Date().millisecondsSince1970
          self.traceSuccess(
            endpoint: endpoint,
            requestStart: requestStartTime,
            requestEnd: requestEndTime,
            response: response as? HTTPURLResponse,
            data: data)

          let model: E.Response = try self.handlePipelineFor(
            with: (data: data, response: response, error: error),
            endpoint: endpoint,
            request: urlRequest,
            requestStartTime: requestStartTime,
            requestEndTime: requestEndTime)

          let code = (response as? HTTPURLResponse)?.statusCode ?? 0

          queue.async {
            let headers: [AnyHashable: String] = (response as? HTTPURLResponse)?
              .allHeaderFields
              .compactMapValues { "\($0)" } ?? [:]
            completion(.success((model, code, ResilientNetworkKitHeaders(headers: headers))))
          }
        } catch {
          self.handleRetry(
            for: error.asNetworkKitError ?? ResilientNetworkKitError.unknown(error: error),
            currentRetry: currentRetry,
            retry: retry,
            endpoint: endpoint,
            receiveOn: queue,
            requestStartTime: requestStartTime,
            completion: completion)
        }
      }
      task.priority = endpoint.priority
      task.resume()
    } catch {
      traceFailure(
        endpoint,
        startTime: requestStartTime,
        error: ResilientNetworkKitError.encodeBodyFailed(error: error))
      queue.async { completion(.failure(ResilientNetworkKitError.encodeBodyFailed(error: error))) }
    }
  }

  private func handleRetry<E: Endpoint>(for error: ResilientNetworkKitError,
                                        currentRetry: Int,
                                        retry: RetryPolicy,
                                        endpoint: E,
                                        receiveOn queue: DispatchQueueType,
                                        requestStartTime: TimeInterval,
                                        completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)
  {
    let retryConfig = retry.retryConfiguration(forAttempt: currentRetry + 1)
    if retryConfig.shouldRetry {
      retryDispatchQueue.asyncAfter(deadline: .now() + retryConfig.delay) { [weak self] in
        guard let self else { return }
        self.performRequest(
          currentRetry: currentRetry + 1,
          endpoint: endpoint,
          retry: retry,
          receiveOn: queue,
          requestStartTime: requestStartTime,
          completion: completion)
      }
    } else {
      traceFailure(endpoint, startTime: requestStartTime, error: error)
      queue.async { completion(.failure(error)) }
    }
  }

  private func handlePipelineFor<E: Endpoint>(with result: URLSessionTaskResult,
                                              endpoint: E,
                                              request: URLRequest,
                                              requestStartTime: TimeInterval,
                                              requestEndTime: TimeInterval) throws
    -> E.Response
  {
    try responsePipeline
      .interceptError(result.error, endpoint: endpoint)
      .interceptStatus(
        result: result,
        request: request,
        endpoint: endpoint,
        requestStartTime: requestStartTime,
        requestEndTime: requestEndTime)
      .interceptData(result.data, endpoint: endpoint)
  }

  private func mutate<E: Endpoint>(endpoint: E) -> E {
    var mutableEnpoint = endpoint
    for interceptor in requestInterceptors {
      mutableEnpoint = interceptor.modify(endpoint: mutableEnpoint)
    }
    return mutableEnpoint
  }

  private func makeURLRequest(with endpoint: some Endpoint) throws -> URLRequest {
    var urlRequest = URLRequest(url: endpoint.url)
    for header in endpoint.headers {
      urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
    }
    urlRequest.httpMethod = endpoint.method.rawValue
    urlRequest.timeoutInterval = endpoint.timeout
    urlRequest.cachePolicy = endpoint.cachePolicy

    let encoder = resolveEncoder(endpoint)
    try encoder.encode(endpoint, &urlRequest)

    return urlRequest
  }

  private func resolveEncoder(_ endpoint: some Endpoint) -> RequestQueryEncodable {
    switch endpoint.httpBodyEncoding {
    case .json: return JSONEncoded()
    case .urlencoded: return URLEncoded()
    case let .custom(encoder): return encoder
    }
  }
}

// MARK: - Tracing Helpers

private extension ResilientNetworkKitImp {
  func tracePending(_ endpoint: some Endpoint, startTime: TimeInterval) {
    networkTraceInspector?.add(
      endpoint: endpoint,
      startTime: startTime,
      endTime: nil,
      status: .pending,
      httpURLResponse: nil,
      data: nil,
      error: nil)
  }

  func traceSuccess(endpoint: some Endpoint,
                    requestStart: TimeInterval,
                    requestEnd: TimeInterval,
                    response: URLResponse?,
                    data: Data?)
  {
    networkTraceInspector?.update(
      endpoint: endpoint,
      startTime: requestStart,
      endTime: requestEnd,
      httpURLResponse: response as? HTTPURLResponse,
      data: data,
      error: nil)
  }

  func traceFailure(_ endpoint: some Endpoint,
                    startTime: TimeInterval,
                    error: ResilientNetworkKitError)
  {
    networkTraceInspector?.update(
      endpoint: endpoint,
      startTime: startTime,
      endTime: Date().millisecondsSince1970,
      httpURLResponse: nil,
      data: nil,
      error: error)
  }
}
