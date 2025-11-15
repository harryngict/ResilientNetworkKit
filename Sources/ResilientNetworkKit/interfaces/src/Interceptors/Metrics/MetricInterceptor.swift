import Foundation

/// @mockable
public protocol MetricInterceptor {
  func notify(metrics: URLSessionTaskMetricsProtocol)
}
