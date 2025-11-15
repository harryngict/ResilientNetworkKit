import Foundation

/// @mockable
public protocol NetworkTraceInspector: Sendable {
  func add(endpoint: some Endpoint,
           startTime: TimeInterval,
           endTime: TimeInterval?,
           status: NetworkRequestStatus,
           httpURLResponse: HTTPURLResponse?,
           data: Data?,
           error: ResilientNetworkKitError?)
  func update(endpoint: some Endpoint,
              startTime: TimeInterval,
              endTime: TimeInterval,
              httpURLResponse: HTTPURLResponse?,
              data: Data?,
              error: ResilientNetworkKitError?)
  func clearAll()
}
