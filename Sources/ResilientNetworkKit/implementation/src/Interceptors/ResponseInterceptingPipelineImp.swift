import Foundation
import ResilientNetworkKit

// MARK: - ResponseInterceptingPipelineImp

final class ResponseInterceptingPipelineImp: ResponseInterceptingPipeline {
  // MARK: Lifecycle

  init(errorInterceptor: ErrorInterceptor,
       responseStatusInterceptor: ResponseStatusInterceptor,
       conflictJustifier: ConflictJustifier,
       responseErrorInspector: ResponseErrorInspector,
       responseParserInterceptor: ResponseParserInterceptor,
       responseMonitorInterceptor: ResponseMonitorInterceptor)
  {
    self.errorInterceptor = errorInterceptor
    self.responseStatusInterceptor = responseStatusInterceptor
    self.conflictJustifier = conflictJustifier
    self.responseErrorInspector = responseErrorInspector
    self.responseParserInterceptor = responseParserInterceptor
    self.responseMonitorInterceptor = responseMonitorInterceptor
  }

  // MARK: Internal

  func interceptError(_ error: Error?,
                      endpoint: some Endpoint) throws
    -> ResponseStatusIntercepting
  {
    guard let error = errorInterceptor.intercept(error, endpoint: endpoint) else {
      return self
    }
    throw error
  }

  func interceptStatus(result: URLSessionTaskResult,
                       request: URLRequest,
                       endpoint: some Endpoint,
                       requestStartTime: TimeInterval,
                       requestEndTime: TimeInterval) throws
    -> ResponseDataIntercepting
  {
    guard let httpResponse = result.response as? HTTPURLResponse else {
      throw ResilientNetworkKitError.httpResponseTypeCastFailed
    }

    responseMonitorInterceptor.monitorResponse(
      endpoint: endpoint,
      response: httpResponse,
      error: result.error,
      data: result.data,
      requestStartTime: requestStartTime,
      requestEndTime: requestEndTime)

    let statusCode = responseStatusInterceptor.intercept(httpResponse, endpoint: endpoint)

    switch statusCode {
    case .success:
      break

    case .badRequest,
         .forbidden,
         .methodNotAllowed,
         .otherClientError,
         .timeout,
         .tooManyRequests,
         .unauthorised:
      let errorPayload = createClientError(
        endpoint,
        statusCode,
        httpResponse.allHeaderFields,
        request,
        result.error,
        result.data)
      throw ResilientNetworkKitError.clientError(error: errorPayload)

    case .conflict:
      throw conflictJustifier.justify(payload: result.data)

    case .unknown:
      throw ResilientNetworkKitError.serverError(
        response: httpResponse,
        error: result.error,
        data: result.data)

    default:
      throw ResilientNetworkKitError.serverError(
        response: httpResponse,
        error: result.error,
        data: result.data)
    }

    return self
  }

  func interceptData<E: Endpoint>(_ data: Data?, endpoint: E) throws -> E.Response {
    try responseParserInterceptor.intercept(data, endpoint: endpoint)
  }

  // MARK: Private

  private let errorInterceptor: ErrorInterceptor
  private let responseStatusInterceptor: ResponseStatusInterceptor
  private let responseErrorInspector: ResponseErrorInspector
  private let responseParserInterceptor: ResponseParserInterceptor
  private let conflictJustifier: ConflictJustifier
  private let responseMonitorInterceptor: ResponseMonitorInterceptor
}

// MARK: - Private

private extension ResponseInterceptingPipelineImp {
  func createClientError(_ endpoint: some Endpoint,
                         _ statusCode: StatusCode,
                         _ allHeaderFields: [AnyHashable: Any],
                         _ request: URLRequest,
                         _ error: Error?,
                         _ data: Data?)
    -> ResilientNetworkKitError.ClientError
  {
    let payload = responseErrorInspector.inspect(data, endpoint: endpoint)

    let userInfo = [
      Key.request: request as Any,
      Key.error: error as Any,
      Key.rawData: data as Any,
      Key.payload: payload,
    ]

    return ResilientNetworkKitError.ClientError(
      statusCode: statusCode,
      allHeaderFields: allHeaderFields,
      userInfo: userInfo)
  }

  private enum Key {
    static let request = "request"
    static let error = "error"
    static let rawData = "data"
    static let payload = "decodedResponse"
  }
}
