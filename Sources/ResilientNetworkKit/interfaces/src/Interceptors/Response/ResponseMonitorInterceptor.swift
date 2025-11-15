import Foundation

/// @mockable
public protocol ResponseMonitorInterceptor: Sendable {
  func monitorResponse(endpoint: some Endpoint,
                       response: HTTPURLResponse?,
                       error: Error?,
                       data: Data?,
                       requestStartTime: TimeInterval,
                       requestEndTime: TimeInterval)
}
