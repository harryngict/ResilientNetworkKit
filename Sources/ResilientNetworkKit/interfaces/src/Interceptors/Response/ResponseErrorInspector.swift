import Foundation

/// @mockable
public protocol ResponseErrorInspector: Sendable {
  func inspect(_ data: Data?, endpoint: some Endpoint) -> Any
}
