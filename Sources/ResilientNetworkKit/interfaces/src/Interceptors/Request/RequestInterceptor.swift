import Foundation

/// @mockable
public protocol RequestInterceptor: Sendable {
  func modify<E: Endpoint>(endpoint: E) -> E
}
