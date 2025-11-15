import Foundation

/// @mockable
public protocol URLSessionTaskMetricsProtocol {
  /// the time elapsed since the task was picked up for execution, until the moment it was finished
  var taskInterval: DateInterval { get }

  /// a list of metrics associated with the task
  var transactionMetrics: [URLSessionTaskTransactionMetrics] { get }

  /// the number of bytes received
  var countOfBytesReceived: Int64 { get }

  /// the number of bytes sent
  var countOfBytesSent: Int64 { get }
}
