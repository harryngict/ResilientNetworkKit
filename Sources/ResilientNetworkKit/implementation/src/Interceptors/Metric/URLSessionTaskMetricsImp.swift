import Foundation
import ResilientNetworkKit

// MARK: - URLSessionTaskMetricsImp

struct URLSessionTaskMetricsImp: URLSessionTaskMetricsProtocol {
  // MARK: Lifecycle

  init(taskMetrics: URLSessionTaskMetrics, task: URLSessionTask) {
    taskInterval = taskMetrics.taskInterval
    transactionMetrics = taskMetrics.transactionMetrics
    countOfBytesReceived = task.countOfBytesReceived
    countOfBytesSent = task.countOfBytesSent
  }

  // MARK: Internal

  let taskInterval: DateInterval
  let transactionMetrics: [URLSessionTaskTransactionMetrics]
  let countOfBytesReceived: Int64
  let countOfBytesSent: Int64
}

// MARK: Equatable

extension URLSessionTaskMetricsImp: Equatable {
  static func == (lhs: URLSessionTaskMetricsImp,
                  rhs: URLSessionTaskMetricsImp)
    -> Bool
  {
    lhs.taskInterval.duration == rhs.taskInterval.duration
      && lhs.transactionMetrics == rhs.transactionMetrics
      && lhs.countOfBytesReceived == rhs.countOfBytesReceived
      && lhs.countOfBytesSent == rhs.countOfBytesSent
  }
}

// MARK: - Convenience Accessors

extension URLSessionTaskMetricsProtocol {
  var statusCode: String {
    guard
      let urlResponse = transactionMetrics.last?.response,
      let httpResponse = urlResponse as? HTTPURLResponse else
    {
      return ResilientNetworkKitConstants.Message.noStatusCode
    }

    return httpResponse.statusCode.description
  }

  var endpointURL: String {
    guard let url = transactionMetrics.first?.request.url else {
      return ResilientNetworkKitConstants.Message.noURL
    }

    var components = URLComponents()
    components.scheme = url.scheme
    components.host = url.host
    components.path = url.path

    return components.url?.absoluteString ?? ResilientNetworkKitConstants.Message.noURL
  }

  var durationMs: String {
    let duration: TimeInterval = taskInterval.duration * 1000
    return duration.description
  }

  var bytesSent: String {
    countOfBytesSent.description
  }

  var bytesReceived: String {
    countOfBytesReceived.description
  }

  var headersSentCount: String {
    guard let headers = transactionMetrics.first?.request.allHTTPHeaderFields else {
      return ResilientNetworkKitConstants.Message.noHeadersSent
    }

    return headers.count.description
  }

  var headersReceivedCount: String {
    guard
      let urlResponse = transactionMetrics.last?.response,
      let httpResponse = urlResponse as? HTTPURLResponse else
    {
      return ResilientNetworkKitConstants.Message.noHeadersReceived
    }

    return httpResponse.allHeaderFields.count.description
  }
}
