import Foundation

/// @mockable
public protocol ResponseStatusInterceptor: Sendable {
  func intercept(_ response: HTTPURLResponse, endpoint: some Endpoint) -> StatusCode
}
